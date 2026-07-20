import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Stock Movement model (drives Recent Activity + Weekly Stock Movement)
class StockMovement {
  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.action,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    required this.timestamp,
  });

  final String id;
  final String productId;
  final String productName;
  final String action;
  final int quantityChange;
  final int previousQuantity;
  final int newQuantity;
  final DateTime timestamp;

  factory StockMovement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockMovement(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      action: data['action'] as String? ?? '',
      quantityChange: (data['quantityChange'] as num?)?.toInt() ?? 0,
      previousQuantity: (data['previousQuantity'] as num?)?.toInt() ?? 0,
      newQuantity: (data['newQuantity'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get label {
    switch (action) {
      case 'added':
        return '$productName Added';
      case 'updated':
        return '$productName Updated';
      case 'deleted':
        return '$productName Deleted';
      case 'increased':
        return '$productName Quantity Increased';
      case 'decreased':
        return '$productName Quantity Decreased';
      case 'restock':
        return '$productName Restocked';
      case 'low_stock':
        return '$productName Low Stock';
      case 'out_of_stock':
        return '$productName Out of Stock';
      default:
        return '$productName $action';
    }
  }

  IconData get icon {
    switch (action) {
      case 'added':
        return Icons.add;
      case 'updated':
        return Icons.edit_outlined;
      case 'deleted':
        return Icons.delete_outline;
      case 'increased':
      case 'restock':
        return Icons.add_circle_outline;
      case 'decreased':
        return Icons.remove_circle_outline;
      case 'low_stock':
        return Icons.warning_amber_rounded;
      case 'out_of_stock':
        return Icons.remove_shopping_cart_outlined;
      default:
        return Icons.history;
    }
  }
}
