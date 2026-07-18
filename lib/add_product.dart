import 'package:flutter/material.dart';

import 'constants.dart';
import 'product.dart';

// ---------------------------------------------------------------------------
// Add Product
// ---------------------------------------------------------------------------
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, required this.onSave});

  final Future<void> Function(Product) onSave;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _priceController = TextEditingController();
  String _category = 'Cakes';
  DateTime? _expirationDate;
  bool _isSaving = false;

  // Fixed supplier value — no longer user-editable. Every product added
  // from this screen is attributed to the bakery itself.
  static const String _fixedSupplier = 'Pan de Batanguena';

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Firestore assigns the real document id on insert; this placeholder
    // id is discarded by FirestoreInventoryService.addProduct().
    final product = Product(
      id: 'PRD-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _category,
      quantity: int.parse(_quantityController.text),
      minStock: int.parse(_minStockController.text),
      price: double.parse(_priceController.text),
      supplier: _fixedSupplier,
      dateAdded: DateTime.now(),
      expirationDate: _expirationDate,
    );

    setState(() => _isSaving = true);
    await widget.onSave(product);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pastry / Cake')),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                                  color: _expirationDate == null ? Colors.grey : kInk,
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
                  _ModernSaveButton(
                    isLoading: _isSaving,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kInk, letterSpacing: 0.3),
        ),
      );
}

// ---------------------------------------------------------------------------
// Section card wrapper — private to AddProductScreen. Groups related fields
// under a titled, rounded, softly-shadowed card consistent with the app's
// existing pink theme.
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.04),
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
                backgroundColor: kPinkSoft,
                child: Icon(icon, size: 15, color: kPinkPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kInk),
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
// Modern animated Save button — private to AddProductScreen. Full-width,
// Material 3–styled, with a subtle press-scale animation layered on top of
// the normal ripple, and an AnimatedSwitcher-driven loading state.
// ---------------------------------------------------------------------------
class _ModernSaveButton extends StatefulWidget {
  const _ModernSaveButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_ModernSaveButton> createState() => _ModernSaveButtonState();
}

class _ModernSaveButtonState extends State<_ModernSaveButton> {
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
                        key: ValueKey('saving'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      )
                    : const Row(
                        key: ValueKey('save'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Save',
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