import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/reward.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance.collection('products').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
  });
});

final rewardConfigProvider = StreamProvider<RewardConfig>((ref) {
  return FirebaseFirestore.instance.collection('config').doc('rewards').snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      return RewardConfig.fromMap(doc.data()!);
    }
    // Default config if not found
    return RewardConfig(spendingPerPoint: 100, pointsRequiredForReward: 50, rewardDescription: 'Cadeau Gratuit');
  });
});

// Admin Actions Provider
final adminActionsProvider = Provider((ref) => AdminActions());

class AdminActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addProduct(Product product) async {
    await _firestore.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  Future<void> updateRewardConfig(RewardConfig config) async {
    await _firestore.collection('config').doc('rewards').set(config.toMap());
  }

  // Scan Logic: Add points based on spending
  Future<void> addPointsToUser(String userId, double amountSpent) async {
    // 1. Get current reward config
    final configDoc = await _firestore.collection('config').doc('rewards').get();
    double spendingPerPoint = 100.0; // default
    if (configDoc.exists && configDoc.data() != null) {
      spendingPerPoint = (configDoc.data()!['spendingPerPoint'] ?? 100.0).toDouble();
    }

    // Calculate points earned
    int pointsEarned = (amountSpent / spendingPerPoint).floor();

    if (pointsEarned <= 0) return;

    // 2. Add points to user
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("Client introuvable!");
      }
      int currentPoints = snapshot.data()?['loyalty_points'] ?? 0;
      transaction.update(userRef, {'loyalty_points': currentPoints + pointsEarned});
    });

    // 3. Log transaction
    await _firestore.collection('transactions').add({
      'user_id': userId,
      'amount_spent': amountSpent,
      'points_earned': pointsEarned,
      'date': FieldValue.serverTimestamp(),
    });
  }
}
