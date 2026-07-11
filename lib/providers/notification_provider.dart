import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  Announcement({required this.id, required this.title, required this.message, required this.createdAt});

  factory Announcement.fromMap(Map<String, dynamic> map, String id) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('created_at', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Announcement.fromMap(doc.data(), doc.id)).toList();
  });
});

class NotificationActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendNotification(String title, String message) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions());
