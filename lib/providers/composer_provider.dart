import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final composerCategoriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('composer_categories')
      .snapshots()
      .map((doc) {
    if (doc.exists && doc.data() != null) {
      final list = doc.data()!['list'] as List<dynamic>?;
      if (list != null) {
        return list.cast<Map<String, dynamic>>();
      }
    }
    // Default fallback
    return [
      {'key': 'pizza', 'label': 'Pizza', 'icon': '🍕', 'color': 0xFFE53935, 'basePrice': 400.0},
      {'key': 'tacos', 'label': 'Tacos', 'icon': '🌮', 'color': 0xFFF57C00, 'basePrice': 450.0},
      {'key': 'sandwich', 'label': 'Sandwich', 'icon': '🥪', 'color': 0xFF388E3C, 'basePrice': 300.0},
      {'key': 'cheese', 'label': 'Assiette', 'icon': '🧀', 'color': 0xFFF9A825, 'basePrice': 600.0},
    ];
  });
});

class ComposerActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    await _firestore.collection('config').doc('composer_categories').set({
      'list': categories,
    });
  }
}

final composerActionsProvider = Provider((ref) => ComposerActions());
