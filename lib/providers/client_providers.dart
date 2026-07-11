import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class ClientUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String status;
  final int loyaltyPoints;
  final int lifetimePoints;
  final bool isPublic;

  ClientUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.status,
    required this.loyaltyPoints,
    required this.lifetimePoints,
    required this.isPublic,
  });

  factory ClientUser.fromMap(Map<String, dynamic> data, String id) {
    return ClientUser(
      id: id,
      name: data['name'] ?? 'Client',
      email: data['email'],
      phone: data['phone'],
      status: data['status'] ?? 'active',
      loyaltyPoints: data['loyalty_points'] ?? 0,
      lifetimePoints: data['lifetime_points'] ?? (data['loyalty_points'] ?? 0),
      isPublic: data['is_public'] ?? false,
    );
  }
}

final clientUserProvider = StreamProvider<ClientUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return ClientUser.fromMap(doc.data()!, doc.id);
  });
});

class ClientActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deductPoints(String userId, int points) async {
    await _firestore.runTransaction((tx) async {
      final ref = _firestore.collection('users').doc(userId);
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>?;
      final current = (data?['loyalty_points'] ?? 0) as int;
      tx.update(ref, {'loyalty_points': (current - points).clamp(0, 999999)});
    });
  }
}

final clientActionsProvider = Provider((ref) => ClientActions());
class FavoriteProductsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String productId) {
    final newState = Set<String>.from(state);
    if (newState.contains(productId)) {
      newState.remove(productId);
    } else {
      newState.add(productId);
    }
    state = newState;
  }
}

final favoriteProductsProvider = NotifierProvider<FavoriteProductsNotifier, Set<String>>(() {
  return FavoriteProductsNotifier();
});
