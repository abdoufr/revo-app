import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/background_location_service.dart';

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
      .limit(30)
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

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=AIzaSyCtaVXK2Pxms8Y3p_I2ZKvRJR4T9eHxicM',
        },
        body: jsonEncode({
          'to': '/topics/all_users',
          'priority': 'high',
          'notification': {
            'title': title,
            'body': message,
            'sound': 'default',
            'android_channel_id': 'announcements_channel',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          },
          'data': {
            'title': title,
            'body': message,
            'type': 'announcement'
          }
        }),
      );
    } catch (e) {
      debugPrint("FCM push error: $e");
    }

    try {
      await BackgroundLocationService.showNotification(message, title: title);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions());
