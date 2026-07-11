import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardItem {
  final String id;
  final String name;
  final int pointsCost;
  final String imageUrl;

  RewardItem({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'points_cost': pointsCost,
      'image_url': imageUrl,
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map, String id) {
    return RewardItem(
      id: id,
      name: map['name'] ?? '',
      pointsCost: map['points_cost'] ?? 0,
      imageUrl: map['image_url'] ?? '',
    );
  }
}

final rewardCatalogProvider = StreamProvider<List<RewardItem>>((ref) {
  return FirebaseFirestore.instance
      .collection('reward_items')
      .orderBy('points_cost', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => RewardItem.fromMap(doc.data(), doc.id)).toList();
  });
});

class RewardCatalogActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRewardItem(String name, int pointsCost, String base64Image) async {
    await _firestore.collection('reward_items').add({
      'name': name,
      'points_cost': pointsCost,
      'image_url': base64Image,
    });
  }

  Future<void> deleteRewardItem(String id) async {
    await _firestore.collection('reward_items').doc(id).delete();
  }
}

final rewardCatalogActionsProvider = Provider((ref) => RewardCatalogActions());
