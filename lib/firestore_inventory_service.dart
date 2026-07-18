import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';
import 'stock_movement.dart';

// ---------------------------------------------------------------------------
// Firestore Inventory Service
// ---------------------------------------------------------------------------
/// Single source of truth for all product persistence. UI widgets never
/// talk to Firestore directly — everything routes through here. Every
/// stock-affecting operation also writes a `stock_movements` record, which
/// drives both Recent Activity and the Weekly Stock Movement report.
class FirestoreInventoryService {
  FirestoreInventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      _firestore.collection('stock_movements');

  // Cached streams. StreamBuilder resets to a loading state whenever it's
  // handed a *new* Stream instance (via `!=` identity check), even if that
  // stream is conceptually "the same" query. Since getProductsStream() and
  // getMovementsStream() get called again on every rebuild of whatever
  // widget holds the StreamBuilder (e.g. every tab switch), we cache the
  // stream the first time it's built and hand back that same instance every
  // time after — so switching tabs never shows a loading flash again.
  Stream<List<Product>>? _productsStream;
  Stream<List<StockMovement>>? _movementsStream;

  /// Live stream of all products, newest first. The Dashboard and
  /// Inventory pages rebuild automatically whenever this stream emits.
  Stream<List<Product>> getProductsStream() {
    return _productsStream ??= _productsRef
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList())
        .asBroadcastStream();
  }

  /// Live stream of all stock movements, newest first.
  Stream<List<StockMovement>> getMovementsStream() {
    return _movementsStream ??= _movementsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(StockMovement.fromFirestore).toList())
        .asBroadcastStream();
  }

  Future<void> _logMovement({
    required String productId,
    required String productName,
    required String action,
    required int quantityChange,
    required int previousQuantity,
    required int newQuantity,
  }) async {
    await _movementsRef.add({
      'productId': productId,
      'productName': productName,
      'action': action,
      'quantityChange': quantityChange,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addProduct(Product product) async {
    final doc = await _productsRef.add(product.toFirestore());
    await _logMovement(
      productId: doc.id,
      productName: product.name,
      action: 'added',
      quantityChange: product.quantity,
      previousQuantity: 0,
      newQuantity: product.quantity,
    );
  }

  Future<void> updateProduct(Product product, {int? previousQuantity}) async {
    await _productsRef.doc(product.id).update(product.toFirestore());
    await _logMovement(
      productId: product.id,
      productName: product.name,
      action: 'updated',
      quantityChange: previousQuantity == null ? 0 : product.quantity - previousQuantity,
      previousQuantity: previousQuantity ?? product.quantity,
      newQuantity: product.quantity,
    );
  }

  Future<void> deleteProduct(String productId, String productName, int quantity) async {
    await _productsRef.doc(productId).delete();
    await _logMovement(
      productId: productId,
      productName: productName,
      action: 'deleted',
      quantityChange: -quantity,
      previousQuantity: quantity,
      newQuantity: 0,
    );
  }

  Future<void> restockProduct(
    String productId,
    String productName,
    int currentQuantity,
    int addedQuantity,
  ) async {
    final newQuantity = currentQuantity + addedQuantity;
    await _productsRef.doc(productId).update({
      'quantity': FieldValue.increment(addedQuantity),
    });
    await _logMovement(
      productId: productId,
      productName: productName,
      action: 'restock',
      quantityChange: addedQuantity,
      previousQuantity: currentQuantity,
      newQuantity: newQuantity,
    );
  }

  Future<void> updateQuantity(
    String productId,
    String productName,
    int previousQuantity,
    int newQuantity,
  ) async {
    await _productsRef.doc(productId).update({'quantity': newQuantity});
    final delta = newQuantity - previousQuantity;
    await _logMovement(
      productId: productId,
      productName: productName,
      action: delta >= 0 ? 'increased' : 'decreased',
      quantityChange: delta,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
    );
    if (newQuantity == 0) {
      await _logMovement(
        productId: productId,
        productName: productName,
        action: 'out_of_stock',
        quantityChange: 0,
        previousQuantity: previousQuantity,
        newQuantity: newQuantity,
      );
    }
  }

  /// Logs a "Low Stock" activity entry. Called once per low-stock episode
  /// by [LowStockGate] when a product first crosses the minimum threshold.
  Future<void> logLowStock(String productId, String productName, int quantity) async {
    await _logMovement(
      productId: productId,
      productName: productName,
      action: 'low_stock',
      quantityChange: 0,
      previousQuantity: quantity,
      newQuantity: quantity,
    );
  }
}