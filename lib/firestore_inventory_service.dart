import 'dart:async';

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

  // Underlying Firestore listeners are started once, in the constructor
  // above, and kept alive for the lifetime of the app. Each _ReplayStream
  // instance is itself the Stream object handed back by the getters below —
  // created exactly once and reused every call, so calling
  // getProductsStream() again (e.g. on every rebuild) always returns an
  // identical Stream reference. That matters because StreamBuilder only
  // resubscribes (and briefly shows ConnectionState.waiting) when it's
  // handed a genuinely different Stream object.
  //
  // On top of that, _ReplayStream solves a second, separate problem: a
  // plain broadcast stream never replays past events to a listener that
  // subscribes late — and that's exactly what happens whenever a
  // StreamBuilder mounts after the very first page load, e.g. opening
  // Weekly Summary or Low Stock Report from Reports after Dashboard has
  // already been showing data for a while. Without a replay, that new
  // StreamBuilder would never see the data that already arrived and would
  // sit on its loading spinner until some unrelated Firestore write
  // happened to fire. _ReplayStream fixes both: every listener — first or
  // late — gets the latest cached value right away, then live updates.
  late final _ReplayStream<List<Product>> _productsReplay;
  late final _ReplayStream<List<StockMovement>> _movementsReplay;

  /// Live stream of all products, newest first. The Dashboard and
  /// Inventory pages rebuild automatically whenever this stream emits, and
  /// any screen that subscribes later (e.g. after navigating to it) gets
  /// the current data immediately instead of waiting for the next change.
  Stream<List<Product>> getProductsStream() => _productsReplay;

  /// Live stream of all stock movements, newest first. Backs both Recent
  /// Activity and every Reports screen (Weekly Stock Movement chart, Weekly
  /// Summary, Low Stock Report).
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

// ---------------------------------------------------------------------------
// _ReplayStream
// ---------------------------------------------------------------------------
/// Wraps a single-subscription source [Stream] (like a Firestore
/// `.snapshots()` query) into a broadcast-style stream that can be listened
/// to by many widgets over the app's lifetime. It behaves like a normal
/// broadcast stream with one crucial addition: every time `.listen()` is
/// called — whether it's the very first listener or one that joins after
/// data has already arrived — that listener is handed the most recently
/// emitted value right away (if one exists), then continues to receive live
/// updates. A plain `StreamController.broadcast()` only delivers events that
/// happen *after* a given listener subscribes, which is what left screens
/// like Weekly Summary and Low Stock Report stuck showing a permanent
/// loading spinner whenever they were opened after the first snapshot had
/// already come in elsewhere in the app.
///
/// The source is subscribed to exactly once, immediately, for the lifetime
/// of this object — matching the original single-Firestore-listener design.
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
      // Deliver the cached value to this listener alone, asynchronously
      // (matching normal Stream semantics — listen() never delivers data
      // synchronously), before any further live updates arrive.
      scheduleMicrotask(() => onData(_latestValue as T));
    }
    return subscription;
  }
}