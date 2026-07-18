import 'package:flutter/material.dart';

import 'constants.dart';
import 'dashboard.dart';
import 'firestore_inventory_service.dart';
import 'inventory.dart';
import 'product.dart';
import 'reports.dart';
import 'settings.dart';

// ---------------------------------------------------------------------------
// Home Shell (Dashboard / Inventory / Reports / Settings / About)
// ---------------------------------------------------------------------------
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
                      child: BakeryLogo(size: 44),
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
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_navIcons[i],
                    color: selectedIndex == i ? kPinkPrimary : Colors.grey),
                title: Text(
                  i == 0 ? 'Dashboard' : _titles[i],
                  style: TextStyle(
                    color: selectedIndex == i ? kPinkPrimary : null,
                    fontWeight:
                        selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selectedIndex == i,
                selectedTileColor: kPinkSoft.withOpacity(0.5),
                onTap: () {
                  onIndexChanged(i);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
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
      // _AnimatedTabBody keeps all four pages permanently alive via
      // IndexedStack (so their StreamBuilders stay subscribed and never
      // reload), and layers a Tween-driven fade/slide on top purely for the
      // visual transition. Nothing is destroyed or rebuilt on tab switch.
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

  static const List<IconData> _navIcons = [
    Icons.home_rounded,
    Icons.inventory_2_rounded,
    Icons.bar_chart_rounded,
    Icons.settings_rounded,
  ];
}

// ---------------------------------------------------------------------------
// Tab body wrapper — keeps every tab's widget subtree permanently alive via
// [IndexedStack] (so each page's StreamBuilder stays subscribed and never
// shows a loading state again after its first load), while still animating
// the tab switch itself using an explicit Tween-driven fade + slide.
// ---------------------------------------------------------------------------
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
      // Replay the tween from the start on every tab change. The
      // IndexedStack below swaps instantly underneath; this animation is
      // purely a visual transition layered on top of it.
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