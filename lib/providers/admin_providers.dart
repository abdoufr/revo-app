import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/reward.dart';
import 'client_providers.dart';

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance.collection('products').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final rewardConfigProvider = StreamProvider<RewardConfig>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('rewards')
      .snapshots()
      .map((doc) {
        if (doc.exists && doc.data() != null) {
          return RewardConfig.fromMap(doc.data()!);
        }
        // Default config if not found
        return RewardConfig(
          spendingPerPoint: 100,
          pointsRequiredForReward: 50,
          rewardDescription: 'Cadeau Gratuit',
        );
      });
});

final categoriesProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('categories')
      .snapshots()
      .map((doc) {
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
        return snapshot.docs
            .map((doc) => ClientUser.fromMap(doc.data(), doc.id))
            .toList();
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
    await _firestore
        .collection('products')
        .doc(product.id)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  Future<void> toggleProductAvailability(String id, bool isAvailable) async {
    await _firestore.collection('products').doc(id).update({
      'is_available': isAvailable,
    });
  }

  Future<void> updateRewardConfig(RewardConfig config) async {
    await _firestore.collection('config').doc('rewards').set(config.toMap());
  }

  // Scan Logic: Add points based on spending
  Future<void> addPointsToUser(
    String userId,
    double amountSpent, {
    String? adminName,
  }) async {
    // 1. Get current reward config
    final configDoc = await _firestore
        .collection('config')
        .doc('rewards')
        .get();
    double spendingPerPoint = 100.0; // default
    if (configDoc.exists && configDoc.data() != null) {
      spendingPerPoint = (configDoc.data()!['spendingPerPoint'] ?? 100.0)
          .toDouble();
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
      String clientName = snapshot.data()?['name'] ?? 'Client Inconnu';
      int currentPoints = snapshot.data()?['loyalty_points'] ?? 0;
      int lifetimePoints =
          snapshot.data()?['lifetime_points'] ??
          currentPoints; // Fallback for old users

      transaction.update(userRef, {
        'loyalty_points': currentPoints + pointsEarned,
        'lifetime_points': lifetimePoints + pointsEarned,
      });
    });

    // 3. Log transaction
    final userSnap = await _firestore.collection('users').doc(userId).get();
    final clientName = userSnap.data()?['name'] ?? 'Client Inconnu';

    await _firestore.collection('transactions').add({
      'user_id': userId,
      'client_name': clientName,
      'amount_spent': amountSpent,
      'points_earned': pointsEarned,
      'type': 'earn',
      'date': FieldValue.serverTimestamp(),
      'admin_name': adminName ?? 'Admin',
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
      transaction.update(userRef, {
        'loyalty_points': currentPoints - pointsRequired,
      });
    });

    await _firestore.collection('transactions').add({
      'user_id': userId,
      'points_deducted': pointsRequired,
      'type': 'claim',
      'date': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppSettings(
    String name,
    String description,
    String banner,
    double lat,
    double lng,
    List<String> messages,
  ) async {
    await _firestore.collection('config').doc('fastfood').set({
      'fastfoodName': name,
      'fastfoodDescription': description,
      'announcementBanner': banner,
      'storeLat': lat,
      'storeLng': lng,
      'geofenceMessages': messages,
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
  // Écouter les utilisateurs pour avoir un total instantané des points (lifetime_points)
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'client')
      .snapshots()
      .asyncMap((usersSnapshot) async {
        double totalPoints = 0;

        for (var doc in usersSnapshot.docs) {
          totalPoints += ((doc.data()['lifetime_points'] ?? 0) as num)
              .toDouble();
        }

        // Récupérer le nombre de récompenses réclamées
        final claimSnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('type', isEqualTo: 'claim')
            .count()
            .get();

        return {
          'totalClients': usersSnapshot.docs.length,
          'totalPoints': totalPoints.toInt(),
          'rewardsClaimed': claimSnapshot.count ?? 0,
        };
      });
});
