import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class ReferralConfig {
  final int pointsForReferrer;
  final int pointsForReferred;

  ReferralConfig({
    required this.pointsForReferrer,
    required this.pointsForReferred,
  });

  Map<String, dynamic> toMap() {
    return {
      'points_referrer': pointsForReferrer,
      'points_referred': pointsForReferred,
    };
  }

  factory ReferralConfig.fromMap(Map<String, dynamic> map) {
    return ReferralConfig(
      pointsForReferrer: map['points_referrer'] ?? 50,
      pointsForReferred: map['points_referred'] ?? 50,
    );
  }
}

final referralConfigProvider = StreamProvider<ReferralConfig>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('referral')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return ReferralConfig.fromMap(snapshot.data()!);
    } else {
      return ReferralConfig(pointsForReferrer: 50, pointsForReferred: 50);
    }
  });
});

class ReferralActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateConfig(ReferralConfig config) async {
    await _firestore.collection('config').doc('referral').set(config.toMap());
  }

  Future<String> applyReferralCode(String code, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception("Utilisateur non connecté");

    if (code.isEmpty || code.length < 6) {
      throw Exception("Code invalide");
    }

    final codeUpper = code.toUpperCase();
    final myCode = user.uid.substring(0, 6).toUpperCase();

    if (codeUpper == myCode) {
      throw Exception("Vous ne pouvez pas utiliser votre propre code");
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) throw Exception("Compte introuvable");
    if (userDoc.data()?['referred_by'] != null) {
      throw Exception("Vous avez déjà utilisé un code de parrainage");
    }

    // Trouver le parrain
    final query = await _firestore.collection('users').get();
    DocumentSnapshot? referrerDoc;
    for (var doc in query.docs) {
      if (doc.id.toUpperCase().startsWith(codeUpper)) {
        referrerDoc = doc;
        break;
      }
    }

    if (referrerDoc == null) {
      throw Exception("Code parrain introuvable");
    }

    // Récupérer la config pour les points
    final configDoc = await _firestore.collection('config').doc('referral').get();
    int pointsReferrer = 50;
    int pointsReferred = 50;
    if (configDoc.exists && configDoc.data() != null) {
      pointsReferrer = configDoc.data()!['points_referrer'] ?? 50;
      pointsReferred = configDoc.data()!['points_referred'] ?? 50;
    }

    // Transaction pour donner les points aux deux
    await _firestore.runTransaction((transaction) async {
      // Refresh docs inside transaction
      final freshUserDoc = await transaction.get(userDocRef);
      final freshReferrerDoc = await transaction.get(referrerDoc!.reference);

      final freshUserData = freshUserDoc.data() as Map<String, dynamic>?;
      final freshReferrerData = freshReferrerDoc.data() as Map<String, dynamic>?;

      if (freshUserData?['referred_by'] != null) {
        throw Exception("Vous avez déjà été parrainé.");
      }

      final currentUserPoints = (freshUserData?['loyalty_points'] ?? 0) as int;
      final currentReferrerPoints = (freshReferrerData?['loyalty_points'] ?? 0) as int;

      transaction.update(userDocRef, {
        'loyalty_points': currentUserPoints + pointsReferred,
        'referred_by': referrerDoc.id,
      });

      transaction.update(referrerDoc.reference, {
        'loyalty_points': currentReferrerPoints + pointsReferrer,
      });
    });

    return "Parrainage réussi ! Vous gagnez $pointsReferred points.";
  }
}

final referralActionsProvider = Provider((ref) => ReferralActions());
