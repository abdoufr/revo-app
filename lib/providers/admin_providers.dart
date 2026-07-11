import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/reward.dart';
import 'client_providers.dart';

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

final categoriesProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance.collection('config').doc('categories').snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      final list = doc.data()!['list'];
      if (list is List) {
        return List<String>.from(list);
      }
    }
    return ['General'];
  });
});

final allClientsStreamProvider = StreamProvider<List<ClientUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'client')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => ClientUser.fromMap(doc.data(), doc.id)).toList();
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

  Future<void> toggleProductAvailability(String id, bool isAvailable) async {
    await _firestore.collection('products').doc(id).update({'is_available': isAvailable});
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
      int lifetimePoints = snapshot.data()?['lifetime_points'] ?? currentPoints; // Fallback for old users
      
      transaction.update(userRef, {
        'loyalty_points': currentPoints + pointsEarned,
        'lifetime_points': lifetimePoints + pointsEarned,
      });
    });

    // 3. Log transaction
    await _firestore.collection('transactions').add({
      'user_id': userId,
      'amount_spent': amountSpent,
      'points_earned': pointsEarned,
      'type': 'earn',
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> claimReward(String userId, int pointsRequired) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw Exception("Client introuvable!");
      }
      int currentPoints = snapshot.data()?['loyalty_points'] ?? 0;
      if (currentPoints < pointsRequired) {
        throw Exception("Points insuffisants!");
      }
      transaction.update(userRef, {'loyalty_points': currentPoints - pointsRequired});
    });

    await _firestore.collection('transactions').add({
      'user_id': userId,
      'points_deducted': pointsRequired,
      'type': 'claim',
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppSettings(String name, String description, String banner) async {
    await _firestore.collection('config').doc('fastfood').set({
      'fastfoodName': name,
      'fastfoodDescription': description,
      'announcementBanner': banner,
    }, SetOptions(merge: true));
  }

  Future<void> updateCategories(List<String> categories) async {
    await _firestore.collection('config').doc('categories').set({
      'list': categories,
    }, SetOptions(merge: true));
  }

  Future<void> deleteClient(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> resetClientPoints(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'loyalty_points': 0,
      'lifetime_points': 0,
    });
  }
}

// Analytics Provider
final analyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  // We use multiple streams combined or just a unified approach.
  // For simplicity, we can fetch all transactions and users, but using aggregate queries is better.
  // Since StreamProvider doesn't support aggregate queries directly in a live way easily across multiple collections,
  // we'll return a FutureProvider or a manual Stream.
  // Actually, we'll just query the transactions to calculate total points given and fetch user count.
  return FirebaseFirestore.instance.collection('transactions').snapshots().asyncMap((transSnapshot) async {
    double totalPoints = 0;
    int rewardsClaimed = 0;
    for (var doc in transSnapshot.docs) {
      if (doc.data()['type'] == 'earn') {
        totalPoints += (doc.data()['points_earned'] ?? 0);
      } else if (doc.data()['type'] == 'claim') {
        rewardsClaimed++;
      }
    }

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').count().get();
    
    return {
      'totalClients': usersSnapshot.count ?? 0,
      'totalPoints': totalPoints.toInt(),
      'rewardsClaimed': rewardsClaimed,
    };
  });
});
