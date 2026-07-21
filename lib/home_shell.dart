import 'package:flutter/material.dart';

import 'constants.dart';
import 'dashboard.dart';
import 'firestore_inventory_service.dart';
import 'inventory.dart';
import 'product.dart';
import 'reports.dart';
import 'settings.dart';

// Home Shell (Dashboard / Inventory / Reports / Settings / About)
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.products,
    required this.inventoryService,
    required this.selectedIndex,
    required this.notificationsEnabled,
    required this.accentColor,
    required this.onIndexChanged,
    required this.onUpdateProduct,
    required this.onDeleteProduct,
    required this.onAdjustStock,
    required this.onRestockProduct,
    required this.onChangeAccentColor,
    required this.onToggleNotifications,
  });

  final List<Product> products;
  final FirestoreInventoryService inventoryService;
  final int selectedIndex;
  final bool notificationsEnabled;
  final Color accentColor;
  final ValueChanged<int> onIndexChanged;
  final Future<void> Function(Product, {int? previousQuantity}) onUpdateProduct;
  final Future<void> Function(Product) onDeleteProduct;
  final Future<Product> Function(Product, int) onAdjustStock;
  final Future<void> Function(Product, int) onRestockProduct;
  final ValueChanged<Color> onChangeAccentColor;
  final ValueChanged<bool> onToggleNotifications;

  static const _titles = [kAppName, 'Inventory', 'Reports', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(products: products, inventoryService: inventoryService),
      InventoryPage(
        products: products,
        onDeleteProduct: onDeleteProduct,
        onUpdateProduct: onUpdateProduct,
        onAdjustStock: onAdjustStock,
        onRestockProduct: onRestockProduct,
      ),
      ReportsPage(products: products, inventoryService: inventoryService),
      SettingsPage(
        accentColor: accentColor,
        notificationsEnabled: notificationsEnabled,
        onChangeAccentColor: onChangeAccentColor,
        onToggleNotifications: onToggleNotifications,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[selectedIndex],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: selectedIndex == 0
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Stack(
                    children: [
                      const Icon(Icons.notifications_none_rounded),
                      if (notificationsEnabled)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: kPinkPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPinkPrimary, kPinkAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kAppName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Pastries & Cakes Inventory',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Colors.grey),
              title: const Text('Bakery Information'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/bakery-info');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: _AnimatedTabBody(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onIndexChanged,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed('/add-product'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
// Tab body wrapper 
class _AnimatedTabBody extends StatefulWidget {
  const _AnimatedTabBody({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}