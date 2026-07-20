import 'package:cloud_firestore/cloud_firestore.dart';

// Product model
class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minStock,
    required this.price,
    required this.supplier,
    required this.dateAdded,
    this.expirationDate,
  });

  final String id;
  final String name;
  final String category; // 'Cakes' or 'Pastries'
  final int quantity;
  final int minStock;
  final double price;
  final String supplier;
  final DateTime dateAdded;
  final DateTime? expirationDate;

  String get status {
    if (quantity == 0) return 'Out of Stock';
    if (quantity <= minStock) return 'Low Stock';
    return 'In Stock';
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Cakes',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      minStock: (data['minimumStock'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      supplier: data['supplier'] as String? ?? '',
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'minimumStock': minStock,
      'price': price,
      'supplier': supplier,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minStock,
    double? price,
    String? supplier,
    DateTime? dateAdded,
    DateTime? expirationDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      price: price ?? this.price,
      supplier: supplier ?? this.supplier,
      dateAdded: dateAdded ?? this.dateAdded,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}

class ProductDetailsArguments {
  ProductDetailsArguments(this.product);
  final Product product;
}
