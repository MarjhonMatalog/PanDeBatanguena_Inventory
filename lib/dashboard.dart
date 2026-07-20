import 'package:flutter/material.dart';

import 'constants.dart';
import 'firestore_inventory_service.dart';
import 'product.dart';
import 'stock_movement.dart';

// Dashboard
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.products,
    required this.inventoryService,
  });

  final List<Product> products;
  final FirestoreInventoryService inventoryService;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics are calculated live from the Firestore-backed
          // `products` stream — never hardcoded. Double-tap any card to
          // view the matching products.
          DashboardStatsWidget(products: products),
          const SizedBox(height: 20),
          Text('Recent Activity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Card(
            child: StreamBuilder<List<StockMovement>>(
              stream: inventoryService.getMovementsStream(),
              builder: (context, snapshot) {
                final movements = snapshot.data ?? const <StockMovement>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(color: kPinkPrimary)),
                  );
                }
                if (movements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recent activity yet.'),
                  );
                }
                final shown = movements.take(6).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final movement = shown[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPinkSoft,
                        child: Icon(movement.icon, color: kPinkPrimary, size: 18),
                      ),
                      title: Text(movement.label),
                      trailing: Text(
                        _timeAgo(movement.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class DashboardStatsWidget extends StatelessWidget {
  const DashboardStatsWidget({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final cakes = products.where((p) => p.category == 'Cakes').toList();
    final pastries = products.where((p) => p.category == 'Pastries').toList();
    final lowStockItems = products.where((p) => p.status == 'Low Stock').toList();
    final outOfStockItems = products.where((p) => p.status == 'Out of Stock').toList();

    final totalCakes = cakes.fold<int>(0, (sum, p) => sum + p.quantity);
    final totalPastries = pastries.fold<int>(0, (sum, p) => sum + p.quantity);

    final statCards = [
      _StatCard(
        title: 'Total Cakes',
        value: '$totalCakes',
        icon: Icons.cake_rounded,
        color: kPinkPrimary,
        onDoubleTap: () => showProductListSheet(
          context,
          title: 'Available Cakes',
          products: cakes,
        ),
      ),
      _StatCard(
        title: 'Total Pastries',
        value: '$totalPastries',
        icon: Icons.bakery_dining_rounded,
        color: Colors.deepOrangeAccent,
        onDoubleTap: () => showProductListSheet(
          context,
          title: 'Available Pastries',
          products: pastries,
        ),
      ),
      _StatCard(
        title: 'Low Stock',
        value: '${lowStockItems.length}',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
        onDoubleTap: () => showProductListSheet(
          context,
          title: 'Low Stock Items',
          products: lowStockItems,
          showCategory: true,
        ),
      ),
      _StatCard(
        title: 'Out of Stock',
        value: '${outOfStockItems.length}',
        icon: Icons.remove_circle_rounded,
        color: Colors.redAccent,
        onDoubleTap: () => showProductListSheet(
          context,
          title: 'Out of Stock Items',
          products: outOfStockItems,
          showCategory: true,
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statCards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35),
      itemBuilder: (_, index) => statCards[index],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onDoubleTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(title,
                  style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: inkOn(context))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet listing [products] using [ProductTileWidget].
void showProductListSheet(
  BuildContext context, {
  required String title,
  required List<Product> products,
  bool showCategory = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${products.length} item${products.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No items to display.'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) => ProductTileWidget(
                        product: products[index],
                        showCategory: showCategory,
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A single product row used inside inventory status bottom sheets.
/// Status color follows the rule: green = In Stock, orange = Low Stock,
/// red = Out of Stock.
class ProductTileWidget extends StatelessWidget {
  const ProductTileWidget({
    super.key,
    required this.product,
    this.showCategory = false,
  });

  final Product product;
  final bool showCategory;

  Color get _statusColor {
    switch (product.status) {
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get _icon =>
      product.category == 'Cakes' ? Icons.cake_rounded : Icons.bakery_dining_rounded;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: kPinkSoft,
        child: Icon(_icon, color: kPinkPrimary, size: 18),
      ),
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(
        showCategory ? '${product.category} • ${product.quantity} pcs' : '${product.quantity} pcs',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Chip(
        label: Text(product.status, style: TextStyle(fontSize: 10, color: _statusColor)),
        backgroundColor: _statusColor.withOpacity(0.12),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}