import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';
import 'stock_movement.dart';

// Firestore Inventory Service
class FirestoreInventoryService {
  FirestoreInventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _productsReplay = _ReplayStream(
      _productsRef
          .orderBy('dateAdded', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList()),
    );
    _movementsReplay = _ReplayStream(
      _movementsRef
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(StockMovement.fromFirestore).toList()),
    );
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      _firestore.collection('stock_movements');

  late final _ReplayStream<List<Product>> _productsReplay;
  late final _ReplayStream<List<StockMovement>> _movementsReplay;

  Stream<List<Product>> getProductsStream() => _productsReplay;
  Stream<List<StockMovement>> getMovementsStream() => _movementsReplay;

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

  /// Logs a "Low Stock"
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

// _ReplayStream
class _ReplayStream<T> extends Stream<T> {
  _ReplayStream(Stream<T> source) {
    _subscription = source.listen(
      (value) {
        _latestValue = value;
        _hasValue = true;
        _controller.add(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(error, stackTrace);
      },
    );
  }

  final StreamController<T> _controller = StreamController<T>.broadcast();
  late final StreamSubscription<T> _subscription;
  T? _latestValue;
  bool _hasValue = false;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    if (_hasValue && onData != null) {
      scheduleMicrotask(() => onData(_latestValue as T));
    }
    return subscription;
  }
}