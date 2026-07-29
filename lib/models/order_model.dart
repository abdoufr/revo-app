import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  enAttente,
  enPreparation,
  pret,
  livree,
  annulee,
}

extension OrderStatusExtension on OrderStatus {
  String get key {
    switch (this) {
      case OrderStatus.enAttente:
        return 'en_attente';
      case OrderStatus.enPreparation:
        return 'en_preparation';
      case OrderStatus.pret:
        return 'pret';
      case OrderStatus.livree:
        return 'livree';
      case OrderStatus.annulee:
        return 'annulee';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.enAttente:
        return 'En attente ⏳';
      case OrderStatus.enPreparation:
        return 'En préparation 👨‍🍳';
      case OrderStatus.pret:
        return 'Prêt ! 🛍️';
      case OrderStatus.livree:
        return 'Livrée ✅';
      case OrderStatus.annulee:
        return 'Annulée ❌';
    }
  }

  static OrderStatus fromKey(String key) {
    switch (key) {
      case 'en_preparation':
        return OrderStatus.enPreparation;
      case 'pret':
        return OrderStatus.pret;
      case 'livree':
        return OrderStatus.livree;
      case 'annulee':
        return OrderStatus.annulee;
      case 'en_attente':
      default:
        return OrderStatus.enAttente;
    }
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String clientName;
  final String clientPhone;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.clientName,
    required this.clientPhone,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'items': items,
      'totalPrice': totalPrice,
      'status': status.key,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? 'Client Inconnu',
      clientPhone: map['clientPhone'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatusExtension.fromKey(map['status'] as String? ?? 'en_attente'),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
