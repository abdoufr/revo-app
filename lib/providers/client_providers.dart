import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class ClientUser {
  final String id;
  final String name;
  final int loyaltyPoints;
  final int lifetimePoints;

  ClientUser({
    required this.id,
    required this.name,
    required this.loyaltyPoints,
    required this.lifetimePoints,
  });

  factory ClientUser.fromMap(Map<String, dynamic> data, String id) {
    return ClientUser(
      id: id,
      name: data['name'] ?? 'Client',
      loyaltyPoints: data['loyalty_points'] ?? 0,
      lifetimePoints: data['lifetime_points'] ?? (data['loyalty_points'] ?? 0),
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
