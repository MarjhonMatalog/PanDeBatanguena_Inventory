import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'constants.dart';
import 'firestore_inventory_service.dart';
import 'product.dart';
import 'stock_movement.dart';

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.products, required this.inventoryService});

  final List<Product> products;
  final FirestoreInventoryService inventoryService;

  @override
  Widget build(BuildContext context) {
    final totalValue = products.fold<double>(0, (sum, product) => sum + (product.price * product.quantity));
    final totalItems = products.fold<int>(0, (sum, product) => sum + product.quantity);
    final lowStockCount = products.where((product) => product.status == 'Low Stock').length;
    final outOfStockCount = products.where((product) => product.status == 'Out of Stock').length;

    final cakesQty = products.where((p) => p.category == 'Cakes').fold<int>(0, (s, p) => s + p.quantity);
    final pastriesQty = products.where((p) => p.category == 'Pastries').fold<int>(0, (s, p) => s + p.quantity);
    final other = math.max(0, totalItems - cakesQty - pastriesQty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _ReportCard(
                      title: 'Total Inventory', value: '$totalItems items', icon: Icons.inventory_2_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ReportCard(
                      title: 'Inventory Value',
                      value: '₱${totalValue.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _ReportCard(
                      title: 'Low Stock Items', value: '$lowStockCount', icon: Icons.warning_amber_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ReportCard(
                      title: 'Out of Stock', value: '$outOfStockCount', icon: Icons.remove_circle_outline)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category Distribution',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Center(
                    child: DonutChart(
                      total: totalItems == 0 ? 1 : totalItems,
                      slices: [
                        DonutSlice('Cakes', cakesQty.toDouble(), kPinkPrimary),
                        DonutSlice('Pastries', pastriesQty.toDouble(), Colors.deepOrangeAccent),
                        DonutSlice('Other', other.toDouble(), Colors.grey.shade300),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Feature 4: Weekly Stock Movement is now driven by real
          // `stock_movements` Firestore data via a live stream, grouped by
          // weekday for the current week (Mon–Sun). No hardcoded values.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Stock Movement',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  StreamBuilder<List<StockMovement>>(
                    stream: inventoryService.getMovementsStream(),
                    builder: (context, snapshot) {
                      final movements = snapshot.data ?? const <StockMovement>[];
                      final values = _weeklyMovementCounts(movements);
                      return WeeklyBarChart(values: values);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: kPinkPrimary),
                  title: const Text('Weekly Summary'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeeklySummaryPage(
                        products: products,
                        inventoryService: inventoryService,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: kPinkPrimary),
                  title: const Text('Low Stock Alert'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LowStockReportPage(inventoryService: inventoryService),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Buckets movements into Mon..Sun counts for the current calendar week.
  List<double> _weeklyMovementCounts(List<StockMovement> movements) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final counts = List<double>.filled(7, 0);
    for (final movement in movements) {
      if (movement.timestamp.isBefore(startOfWeek) || !movement.timestamp.isBefore(endOfWeek)) {
        continue;
      }
      final dayIndex = movement.timestamp.weekday - 1; // 0 = Mon .. 6 = Sun
      counts[dayIndex] += 1;
    }
    return counts;
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 14, backgroundColor: kPinkSoft, child: Icon(icon, size: 14, color: kPinkPrimary)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class DonutSlice {
  DonutSlice(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.total, required this.slices});

  final int total;
  final List<DonutSlice> slices;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: total.toDouble()),
            child: Center(
              child: Text('$total\nitems', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: slices.map((slice) {
            final pct = total == 0 ? 0 : (slice.value / total * 100).round();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${slice.label} $pct%', style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.total});
  final List<DonutSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -math.pi / 2;
    final strokeWidth = size.width * 0.18;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = total == 0 ? 0.0 : (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.values});

  final List<double> values;
  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 0.0 : values.reduce(math.max);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final heightFactor = maxVal == 0 ? 0.0 : values[i] / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${values[i].toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: heightFactor.clamp(0.05, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kPinkPrimary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_labels[i], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature 5: Weekly Summary page
// ---------------------------------------------------------------------------
class WeeklySummaryPage extends StatelessWidget {
  const WeeklySummaryPage({
    super.key,
    required this.products,
    required this.inventoryService,
  });

  final List<Product> products;
  final FirestoreInventoryService inventoryService;

  @override
  Widget build(BuildContext context) {
    final totalValue = products.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
    final lowStockCount = products.where((p) => p.status == 'Low Stock').length;
    final outOfStockCount = products.where((p) => p.status == 'Out of Stock').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Summary')),
      body: StreamBuilder<List<StockMovement>>(
        stream: inventoryService.getMovementsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPinkPrimary));
          }
          final movements = snapshot.data ?? const <StockMovement>[];
          final now = DateTime.now();
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final weekMovements =
              movements.where((m) => !m.timestamp.isBefore(startOfWeek)).toList();

          final added = weekMovements.where((m) => m.action == 'added').length;
          final sold = weekMovements.where((m) => m.action == 'decreased').length;
          final restocks = weekMovements.where((m) => m.action == 'restock').length;
          final totalMovement = weekMovements.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryTile(label: 'Total Products Added', value: '$added', icon: Icons.add_box_outlined),
              _SummaryTile(label: 'Total Products Sold', value: '$sold', icon: Icons.shopping_bag_outlined),
              _SummaryTile(label: 'Total Restocks', value: '$restocks', icon: Icons.inventory_outlined),
              _SummaryTile(label: 'Total Stock Movement', value: '$totalMovement', icon: Icons.swap_vert),
              _SummaryTile(
                  label: 'Current Inventory Value',
                  value: '₱${totalValue.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined),
              _SummaryTile(label: 'Low Stock Items', value: '$lowStockCount', icon: Icons.warning_amber_rounded),
              _SummaryTile(label: 'Out of Stock Items', value: '$outOfStockCount', icon: Icons.remove_circle_outline),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: kPinkSoft, child: Icon(icon, color: kPinkPrimary)),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature 6: Low Stock Report page
// ---------------------------------------------------------------------------
class LowStockReportPage extends StatelessWidget {
  const LowStockReportPage({super.key, required this.inventoryService});

  final FirestoreInventoryService inventoryService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock Report')),
      body: StreamBuilder<List<Product>>(
        stream: inventoryService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPinkPrimary));
          }
          final products = (snapshot.data ?? const <Product>[])
              .where((p) => p.status == 'Low Stock' || p.status == 'Out of Stock')
              .toList()
            ..sort((a, b) => a.quantity.compareTo(b.quantity));

          if (products.isEmpty) {
            return const Center(child: Text('No low stock items right now.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final product = products[index];
              final color = product.status == 'Out of Stock' ? Colors.red : Colors.orange;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(Icons.warning_amber_rounded, color: color),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${product.category} • Qty: ${product.quantity} • Min: ${product.minStock}'),
                  trailing: Chip(
                    label: Text(product.status, style: TextStyle(fontSize: 11, color: color)),
                    backgroundColor: color.withOpacity(0.12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}