import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'add_product.dart';
import 'constants.dart';
import 'firestore_inventory_service.dart';
import 'home_shell.dart';
import 'inventory.dart' show showRestockDialog;
import 'login.dart';
import 'product.dart';
import 'product_details.dart';
import 'settings.dart' show BakeryInfoPage, AboutPage;
import 'splash.dart';

class SweetStockApp extends StatefulWidget {
  const SweetStockApp({super.key});

  @override
  State<SweetStockApp> createState() => _SweetStockAppState();
}

class _SweetStockAppState extends State<SweetStockApp> {
  Color _accentColor = kPinkPrimary;
  bool _notificationsEnabled = true;

  // Firestore-backed inventory service. All product CRUD flows through here.
  final FirestoreInventoryService _inventoryService = FirestoreInventoryService();

  int _selectedIndex = 0;

  void _changeAccentColor(Color color) => setState(() => _accentColor = color);

  void _toggleNotifications(bool value) =>
      setState(() => _notificationsEnabled = value);

  Future<void> _addProduct(Product product) async {
    await _inventoryService.addProduct(product);
    setState(() {
      _selectedIndex = 1;
    });
  }

  Future<void> _updateProduct(Product updatedProduct, {int? previousQuantity}) async {
    await _inventoryService.updateProduct(updatedProduct, previousQuantity: previousQuantity);
  }

  Future<void> _deleteProduct(Product product) async {
    await _inventoryService.deleteProduct(product.id, product.name, product.quantity);
  }

  Future<Product> _adjustStock(Product product, int delta) async {
    final nextQuantity = math.max(0, product.quantity + delta);
    await _inventoryService.updateQuantity(
      product.id,
      product.name,
      product.quantity,
      nextQuantity,
    );
    return product.copyWith(quantity: nextQuantity);
  }

  Future<void> _restockProduct(Product product, int addedQuantity) async {
    await _inventoryService.restockProduct(
      product.id,
      product.name,
      product.quantity,
      addedQuantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme;

    ThemeData buildTheme(Brightness brightness) {
      final isDark = brightness == Brightness.dark;
      // In dark mode we seed with the bakery purple (matching the logo)
      // instead of the pink accent, since pink-on-black reads muddier than
      // pink-on-white. Light mode is unchanged.
      final scheme = ColorScheme.fromSeed(
        seedColor: isDark ? kPurplePrimary : _accentColor,
        brightness: brightness,
      ).copyWith(
        secondary: kPinkAccent,
        error: isDark ? const Color(0xFFCF6679) : null,
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: isDark ? kDarkBackground : const Color(0xFFFFF8FA),
        textTheme: isDark ? ThemeData.dark().textTheme : baseTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? kDarkBackgroundAlt : Colors.white,
          foregroundColor: isDark ? kInkDark : kInk,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: isDark ? kDarkCard : Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? kDarkSurface : kPinkSoft.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: isDark ? kPurplePrimary : kPinkPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: isDark ? kPurplePrimary : kPinkPrimary,
          unselectedItemColor: Colors.grey,
          backgroundColor: isDark ? kDarkBackgroundAlt : Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: isDark ? kPurplePrimary : kPinkPrimary,
          foregroundColor: Colors.white,
        ),
      );
    }

    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      // Adaptive dark mode: follow the device's system setting automatically.
      // No manual in-app toggle — Android/iOS system settings are the source
      // of truth, per Material 3 guidance.
      themeMode: ThemeMode.system,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => StreamBuilder<List<Product>>(
              stream: _inventoryService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const InventoryLoadingScreen();
                }
                if (snapshot.hasError) {
                  return InventoryErrorScreen(message: '${snapshot.error}');
                }
                final products = snapshot.data ?? const <Product>[];
                return LowStockGate(
                  products: products,
                  inventoryService: _inventoryService,
                  child: HomeShell(
                    products: products,
                    inventoryService: _inventoryService,
                    selectedIndex: _selectedIndex,
                    notificationsEnabled: _notificationsEnabled,
                    accentColor: _accentColor,
                    onIndexChanged: (value) => setState(() => _selectedIndex = value),
                    onUpdateProduct: _updateProduct,
                    onDeleteProduct: _deleteProduct,
                    onAdjustStock: _adjustStock,
                    onRestockProduct: _restockProduct,
                    onChangeAccentColor: _changeAccentColor,
                    onToggleNotifications: _toggleNotifications,
                  ),
                );
              },
            ),
        '/add-product': (context) => AddProductScreen(onSave: _addProduct),
        '/product-details': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as ProductDetailsArguments;
          return ProductDetailsScreen(
            product: args.product,
            onDelete: _deleteProduct,
            onUpdate: _updateProduct,
            onRestock: _restockProduct,
            onAdjustStock: _adjustStock,
          );
        },
        '/bakery-info': (context) => const BakeryInfoPage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Low Stock Gate — watches the live product stream and automatically shows
// the Low Stock Alert dialog the first time a product crosses into the
// "Low Stock" status. It resets so the dialog can fire again the next time
// the same product dips low after being restocked above the threshold.
// ---------------------------------------------------------------------------
class LowStockGate extends StatefulWidget {
  const LowStockGate({
    super.key,
    required this.products,
    required this.inventoryService,
    required this.child,
  });

  final List<Product> products;
  final FirestoreInventoryService inventoryService;
  final Widget child;

  @override
  State<LowStockGate> createState() => _LowStockGateState();
}

class _LowStockGateState extends State<LowStockGate> {
  final Set<String> _dialogShownFor = {};
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLowStock());
  }

  @override
  void didUpdateWidget(covariant LowStockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLowStock());
  }

  void _checkLowStock() {
    if (!mounted) return;

    final currentLowIds = widget.products
        .where((p) => p.status == 'Low Stock')
        .map((p) => p.id)
        .toSet();

    // A product that is no longer low stock (restocked, or fell to zero)
    // clears its "already shown" flag so the alert can fire again later.
    _dialogShownFor.removeWhere((id) => !currentLowIds.contains(id));

    if (_isDialogOpen) return;

    // Gather every currently-low product that hasn't been surfaced yet and
    // show them together in a single dialog, instead of one popup per item.
    final newlyLow = widget.products
        .where((p) => p.status == 'Low Stock' && !_dialogShownFor.contains(p.id))
        .toList();

    if (newlyLow.isEmpty) return;

    for (final product in newlyLow) {
      _dialogShownFor.add(product.id);
      widget.inventoryService.logLowStock(product.id, product.name, product.quantity);
    }
    _showLowStockDialog(newlyLow);
  }

  Future<void> _showLowStockDialog(List<Product> products) async {
    _isDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (_) => _LowStockAlertDialog(
        products: products,
        inventoryService: widget.inventoryService,
      ),
    );
    _isDialogOpen = false;

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkLowStock());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------------
// Low Stock Alert dialog — shows every product that just crossed into Low
// Stock in one card instead of stacking popups one after another. Each row
// has its own inline Restock button so restocking one item doesn't close
// the dialog or interrupt review of the rest; the dialog auto-closes once
// every item in the batch has been restocked or dismissed.
// ---------------------------------------------------------------------------
class _LowStockAlertDialog extends StatefulWidget {
  const _LowStockAlertDialog({required this.products, required this.inventoryService});

  final List<Product> products;
  final FirestoreInventoryService inventoryService;

  @override
  State<_LowStockAlertDialog> createState() => _LowStockAlertDialogState();
}

class _LowStockAlertDialogState extends State<_LowStockAlertDialog> {
  late final List<Product> _items = List.of(widget.products);
  final Set<String> _restocking = {};

  Future<void> _restock(Product product) async {
    final qty = await showRestockDialog(context, product);
    if (qty == null || qty <= 0) return;

    setState(() => _restocking.add(product.id));
    await widget.inventoryService.restockProduct(
      product.id,
      product.name,
      product.quantity,
      qty,
    );
    if (!mounted) return;

    setState(() {
      _restocking.remove(product.id);
      _items.removeWhere((p) => p.id == product.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} restocked successfully')),
    );

    // Once every item in the batch has been handled, close automatically.
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const warningColor = Colors.orange;
    final count = _items.length;

    return Dialog(
      backgroundColor: isDark ? kDarkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: warningColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Stock Alert',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: inkOn(context),
                          ),
                        ),
                        Text(
                          count == 0
                              ? 'All caught up'
                              : count == 1
                                  ? '1 item needs restocking'
                                  : '$count items need restocking',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: count == 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Every item has been restocked. 🎉',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final product = _items[index];
                          final isBusy = _restocking.contains(product.id);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: warningColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: warningColor.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: kPinkSoft,
                                  child: Icon(
                                    product.category == 'Cakes'
                                        ? Icons.cake_rounded
                                        : Icons.bakery_dining_rounded,
                                    color: kPinkPrimary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: inkOn(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${product.quantity} pcs left',
                                        style: const TextStyle(fontSize: 11, color: warningColor),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 32,
                                  child: OutlinedButton(
                                    onPressed: isBusy ? null : () => _restock(product),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: warningColor,
                                      side: BorderSide(color: warningColor.withOpacity(0.5)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: isBusy
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: warningColor,
                                            ),
                                          )
                                        : const Text('Restock', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? kInkDark : kInk,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(count == 0 ? 'Close' : 'Restock Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error states for the Firestore-backed home stream
// ---------------------------------------------------------------------------
class InventoryLoadingScreen extends StatelessWidget {
  const InventoryLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kPinkPrimary),
            SizedBox(height: 16),
            Text('Loading inventory...'),
          ],
        ),
      ),
    );
  }
}

class InventoryErrorScreen extends StatelessWidget {
  const InventoryErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text('Unable to load inventory',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}