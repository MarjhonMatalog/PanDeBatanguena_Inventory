import 'package:flutter/material.dart';

import 'constants.dart';
import 'edit_product.dart';
import 'inventory.dart';
import 'product.dart';

// ---------------------------------------------------------------------------
// Product Details
// ---------------------------------------------------------------------------
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onUpdate,
    required this.onRestock,
    required this.onAdjustStock,
  });

  final Product product;
  final Future<void> Function(Product) onDelete;
  final Future<void> Function(Product, {int? previousQuantity}) onUpdate;
  final Future<void> Function(Product, int) onRestock;
  final Future<Product> Function(Product, int) onAdjustStock;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Product _product;
  final List<String> _stockHistory = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _addStock() async {
    final updated = await widget.onAdjustStock(_product, 1);
    setState(() {
      _product = updated;
      _stockHistory.insert(0, 'Added 1 unit — now ${updated.quantity} pcs');
    });
    if (mounted) await showSuccessDialog(context, 'Inventory Updated Successfully');
  }

  Future<void> _reduceStock() async {
    final updated = await widget.onAdjustStock(_product, -1);
    setState(() {
      _product = updated;
      _stockHistory.insert(0, 'Reduced 1 unit — now ${updated.quantity} pcs');
    });
    if (!mounted) return;
    if (updated.quantity <= updated.minStock && updated.quantity > 0) {
      await showLowStockWarning(context, updated);
    } else {
      await showSuccessDialog(context, 'Inventory Updated Successfully');
    }
  }

  Future<void> _restock() async {
    final qty = await showRestockDialog(context, _product);
    if (qty == null || qty <= 0) return;
    await widget.onRestock(_product, qty);
    setState(() {
      _product = _product.copyWith(quantity: _product.quantity + qty);
      _stockHistory.insert(0, 'Restocked +$qty — now ${_product.quantity} pcs');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product restocked successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: kPinkSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPinkAccent.withOpacity(0.4)),
              ),
              child: Center(
                child: Icon(
                  product.category == 'Cakes' ? Icons.cake_rounded : Icons.bakery_dining_rounded,
                  size: 48,
                  color: kPinkPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Product Name', value: product.name),
                    _DetailRow(label: 'Product ID', value: product.id),
                    _DetailRow(label: 'Category', value: product.category),
                    _DetailRow(label: 'Quantity', value: '${product.quantity} pcs'),
                    _DetailRow(label: 'Minimum Stock', value: '${product.minStock} pcs'),
                    _DetailRow(label: 'Price', value: '₱${product.price.toStringAsFixed(2)}'),
                    _DetailRow(label: 'Supplier', value: product.supplier),
                    if (product.expirationDate != null)
                      _DetailRow(
                        label: 'Expiration Date',
                        value:
                            '${product.expirationDate!.month.toString().padLeft(2, '0')}/${product.expirationDate!.day.toString().padLeft(2, '0')}/${product.expirationDate!.year}',
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          Chip(
                            label: Text(product.status, style: const TextStyle(fontSize: 11)),
                            backgroundColor: _statusColor(product).withOpacity(0.15),
                            labelStyle: TextStyle(color: _statusColor(product)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(onPressed: _addStock, child: const Text('Add Stock'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(onPressed: _reduceStock, child: const Text('Reduce Stock'))),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton(onPressed: _restock, child: const Text('Restock'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductScreen(
                          product: product,
                          onSave: (updated, {previousQuantity}) async {
                            await widget.onUpdate(updated, previousQuantity: previousQuantity);
                            if (mounted) setState(() => _product = updated);
                          },
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kInk),
                    onPressed: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Delete Product'),
                          content: const Text('Are you sure you want to delete this item?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (shouldDelete ?? false) {
                        await widget.onDelete(product);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Stock History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 8),
            Card(
              child: _stockHistory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Current stock level is based on automatic status updates using the minimum stock rule.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stockHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) => ListTile(
                        leading: const Icon(Icons.history, color: kPinkPrimary),
                        title: Text(_stockHistory[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(Product product) {
    if (product.status == 'Out of Stock') return kInk;
    if (product.status == 'Low Stock') return Colors.orange;
    return Colors.green;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
