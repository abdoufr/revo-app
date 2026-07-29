import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import 'auth_providers.dart';

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
        .toList();
  });
});

final clientOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value ?? ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

class OrderActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String userId,
    required String clientName,
    required String clientPhone,
    required List<CartItem> items,
    required double totalPrice,
  }) async {
    final serializedItems = items.map((item) => item.toMap()).toList();

    await _firestore.collection('orders').add({
      'userId': userId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'items': serializedItems,
      'totalPrice': totalPrice,
      'status': OrderStatus.enAttente.key,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus.key,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final orderActionsProvider = Provider((ref) => OrderActions());
