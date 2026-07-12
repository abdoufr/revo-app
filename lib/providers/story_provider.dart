import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story.dart';

final storiesProvider = StreamProvider<List<StoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('stories')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
        .where((story) => story.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
        .toList();
  });
});

class StoryActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStory(String title, String base64Image) async {
    await _firestore.collection('stories').add({
      'title': title,
      'image_url': base64Image,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStory(String id) async {
    await _firestore.collection('stories').doc(id).delete();
  }
}

final storyActionsProvider = Provider((ref) => StoryActions());
