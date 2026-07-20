import 'package:flutter/material.dart';

import 'constants.dart';
import 'edit_product.dart';
import 'product.dart';

// Inventory
class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.products,
    required this.onDeleteProduct,
    required this.onUpdateProduct,
    required this.onAdjustStock,
    required this.onRestockProduct,
  });

  final List<Product> products;
  final Future<void> Function(Product) onDeleteProduct;
  final Future<void> Function(Product, {int? previousQuantity}) onUpdateProduct;
  final Future<Product> Function(Product, int) onAdjustStock;
  final Future<void> Function(Product, int) onRestockProduct;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((product) {
      final matchesQuery = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'All' ||
          product.category == _filter ||
          product.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search cakes or pastries...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Cakes', 'Pastries', 'Low Stock', 'Out of Stock'].map((filter) {
                final selected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    selectedColor:
                        Theme.of(context).brightness == Brightness.dark ? kPurplePrimary : kPinkPrimary,
                    labelStyle: TextStyle(color: selected ? Colors.white : inkOn(context)),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.products.isEmpty
              ? const _InventoryEmptyState()
              : filtered.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context)
                                .pushNamed('/product-details', arguments: ProductDetailsArguments(product)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: kPinkSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      product.category == 'Cakes'
                                          ? Icons.cake_rounded
                                          : Icons.bakery_dining_rounded,
                                      color: kPinkPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(product.name,
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                            _statusChip(product),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('${product.category} • ₱${product.price.toStringAsFixed(0)}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _QuantityStepButton(
                                              icon: Icons.remove,
                                              onPressed: () =>
                                                  widget.onAdjustStock(product, -1),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                '${product.quantity}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                            _QuantityStepButton(
                                              icon: Icons.add,
                                              onPressed: () =>
                                                  widget.onAdjustStock(product, 1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        color: kPinkPrimary,
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => EditProductScreen(
                                              product: product,
                                              onSave: widget.onUpdateProduct,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        color: Colors.grey,
                                        onPressed: () => confirmDelete(context, product, widget.onDeleteProduct),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _statusChip(Product product) {
    Color color;
    if (product.status == 'Out of Stock') {
      color = kInk;
    } else if (product.status == 'Low Stock') {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    return Chip(
      label: Text(product.status, style: TextStyle(fontSize: 10, color: color)),
      backgroundColor: color.withOpacity(0.12),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _QuantityStepButton extends StatelessWidget {
  const _QuantityStepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kPinkSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: kPinkPrimary),
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No products yet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Tap the + button to add your first cake or pastry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> confirmDelete(
    BuildContext context, Product product, Future<void> Function(Product) onDelete) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.delete_outline, color: kPinkPrimary),
          SizedBox(width: 8),
          Text('Delete Product?'),
        ],
      ),
      content: const Text('Are you sure you want to remove this pastry or cake from inventory?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  if (shouldDelete ?? false) {
    await onDelete(product);
  }
}

Future<void> showSuccessDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kPinkSoft,
            child: const Icon(Icons.check_rounded, color: kPinkPrimary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ),
        ],
      ),
    ),
  );
}

Future<void> showLowStockWarning(BuildContext context, Product product) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color.fromARGB(255, 221, 116, 174)),
          SizedBox(width: 8),
          Text('Low Stock Warning'),
        ],
      ),
      content: Text(
          '${product.name} has reached the minimum stock level. Consider restocking soon.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Restock')),
      ],
    ),
  );
}

Future<int?> showRestockDialog(BuildContext context, Product product) {
  final controller = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        String? errorText;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kPinkSoft,
                child: const Icon(Icons.add_shopping_cart_rounded, color: kPinkPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Restock Product', style: TextStyle(fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Current Quantity: ${product.quantity} pcs',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 28),
              const Text('QUANTITY TO ADD',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter quantity...',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.add_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(controller.text);
                if (qty == null || qty <= 0) {
                  setState(() => errorText = 'Quantity must be greater than zero');
                  return;
                }
                Navigator.pop(context, qty);
              },
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              child: const Text('Restock'),
            ),
          ],
        );
      },
    ),
  );
}