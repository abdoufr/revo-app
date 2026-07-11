import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String imageUrl;
  final String title;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'title': title,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      imageUrl: map['image_url'] ?? '',
      title: map['title'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
