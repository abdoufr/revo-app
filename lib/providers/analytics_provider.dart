import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsData {
  final int totalUsers;
  final int totalPointsDistributed;
  final int totalPointsAvailable;
  final double averagePointsPerUser;
  final int totalReviews;

  AnalyticsData({
    required this.totalUsers,
    required this.totalPointsDistributed,
    required this.totalPointsAvailable,
    required this.averagePointsPerUser,
    required this.totalReviews,
  });
}

final advancedAnalyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final firestore = FirebaseFirestore.instance;

  final usersSnapshot = await firestore.collection('users').get();
  int totalUsers = usersSnapshot.docs.length;
  int totalPointsDistributed = 0;
  int totalPointsAvailable = 0;

  for (var doc in usersSnapshot.docs) {
    totalPointsDistributed += (doc.data()['lifetime_points'] ?? 0) as int;
    totalPointsAvailable += (doc.data()['loyalty_points'] ?? 0) as int;
  }

  double averagePoints = totalUsers > 0 ? totalPointsDistributed / totalUsers : 0.0;

  final reviewsSnapshot = await firestore.collection('reviews').get();
  int totalReviews = reviewsSnapshot.docs.length;

  return AnalyticsData(
    totalUsers: totalUsers,
    totalPointsDistributed: totalPointsDistributed,
    totalPointsAvailable: totalPointsAvailable,
    averagePointsPerUser: averagePoints,
    totalReviews: totalReviews,
  );
});
