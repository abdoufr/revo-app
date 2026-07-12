import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsData {
  final int totalUsers;
  final int totalPointsDistributed;
  final int totalPointsAvailable;
  final double averagePointsPerUser;
  final int totalReviews;
  final int totalVisits;

  AnalyticsData({
    required this.totalUsers,
    required this.totalPointsDistributed,
    required this.totalPointsAvailable,
    required this.averagePointsPerUser,
    required this.totalReviews,
    required this.totalVisits,
  });
}

final visitsStreamProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance.collection('config').doc('analytics').snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      return doc.data()!['total_visits'] ?? 0;
    }
    return 0;
  });
});

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

  final analyticsConfig = await firestore.collection('config').doc('analytics').get();
  int totalVisits = 0;
  if (analyticsConfig.exists && analyticsConfig.data() != null) {
    totalVisits = analyticsConfig.data()?['total_visits'] ?? 0;
  }

  return AnalyticsData(
    totalUsers: totalUsers,
    totalPointsDistributed: totalPointsDistributed,
    totalPointsAvailable: totalPointsAvailable,
    averagePointsPerUser: averagePoints,
    totalReviews: totalReviews,
    totalVisits: totalVisits,
  );
});
