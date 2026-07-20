import 'package:flutter/material.dart';

import 'constants.dart';
import 'product.dart';

// Edit Product
class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.product, required this.onSave});

  final Product product;
  final Future<void> Function(Product, {int? previousQuantity}) onSave;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minStockController;
  late final TextEditingController _priceController;
  late String _category;
  DateTime? _expirationDate;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();

  static const String _fixedSupplier = 'Pan de Batanguena';

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
    _priceController = TextEditingController(text: widget.product.price.toString());
    _category = widget.product.category;
    _expirationDate = widget.product.expirationDate;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiration() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final previousQuantity = widget.product.quantity;
    final updatedProduct = widget.product.copyWith(
      name: _nameController.text.trim(),
      category: _category,
      quantity: int.parse(_quantityController.text),
      minStock: int.parse(_minStockController.text),
      price: double.parse(_priceController.text),
      supplier: _fixedSupplier,
      expirationDate: _expirationDate,
    );
    setState(() => _isSaving = true);
    await widget.onSave(updatedProduct, previousQuantity: previousQuantity);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Product Info',
                    icon: Icons.cake_rounded,
                    children: [
                      _label('PRODUCT NAME'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'e.g. Chocolate Cake'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter a product name' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('CATEGORY'),
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: const [
                          DropdownMenuItem(value: 'Cakes', child: Text('Cakes')),
                          DropdownMenuItem(value: 'Pastries', child: Text('Pastries')),
                        ],
                        onChanged: (value) => setState(() => _category = value ?? 'Cakes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Stock & Pricing',
                    icon: Icons.inventory_2_rounded,
                    children: [
                      _label('QUANTITY'),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter quantity';
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity < 0) return 'Quantity cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('MINIMUM STOCK'),
                      TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter minimum stock';
                          final minStock = int.tryParse(value);
                          if (minStock == null || minStock < 0) return 'Minimum stock cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('UNIT PRICE (₱)'),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0.00'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a price';
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) return 'Price must be positive';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Availability',
                    icon: Icons.event_rounded,
                    children: [
                      _label('EXPIRATION DATE'),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickExpiration,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _expirationDate == null
                                ? kPinkSoft.withOpacity(0.4)
                                : kPinkSoft.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _expirationDate == null
                                  ? Colors.transparent
                                  : kPinkPrimary.withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: _expirationDate == null ? Colors.grey : kPinkPrimary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _expirationDate == null
                                    ? 'MM / DD / YYYY'
                                    : '${_expirationDate!.month.toString().padLeft(2, '0')}/${_expirationDate!.day.toString().padLeft(2, '0')}/${_expirationDate!.year}',
                                style: TextStyle(
                                  color: _expirationDate == null ? Colors.grey : inkOn(context),
                                  fontWeight: _expirationDate == null ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _ModernUpdateButton(
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: inkOn(context), letterSpacing: 0.3),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Section card wrapper — private to EditProductScreen. Groups related
// fields under a titled, rounded, softly-shadowed card consistent with the
// app's existing pink theme (matches AddProductScreen's styling).
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: isDark ? kPurplePrimary.withOpacity(0.25) : kPinkSoft,
                child: Icon(icon, size: 15, color: isDark ? kPurplePrimary : kPinkPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: inkOn(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modern animated Update button — private to EditProductScreen. Full-width,
// Material 3–styled, with a subtle press-scale animation layered on top of
// the normal ripple, and an AnimatedSwitcher-driven loading state.
// ---------------------------------------------------------------------------
class _ModernUpdateButton extends StatefulWidget {
  const _ModernUpdateButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_ModernUpdateButton> createState() => _ModernUpdateButtonState();
}

class _ModernUpdateButtonState extends State<_ModernUpdateButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isLoading) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: disabled ? kPinkPrimary.withOpacity(0.6) : kPinkPrimary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : widget.onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: widget.isLoading
                    ? const Row(
                        key: ValueKey('updating'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Updating...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      )
                    : const Row(
                        key: ValueKey('update'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Update Product',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}