import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamificationConfig {
  final bool isWheelEnabled;
  final int wheelCost;
  final List<String> wheelPrizes;

  GamificationConfig({
    required this.isWheelEnabled,
    required this.wheelCost,
    required this.wheelPrizes,
  });

  Map<String, dynamic> toMap() {
    return {
      'is_wheel_enabled': isWheelEnabled,
      'wheel_cost': wheelCost,
      'wheel_prizes': wheelPrizes,
    };
  }

  factory GamificationConfig.fromMap(Map<String, dynamic> map) {
    return GamificationConfig(
      isWheelEnabled: map['is_wheel_enabled'] ?? false,
      wheelCost: map['wheel_cost'] ?? 50,
      wheelPrizes: List<String>.from(map['wheel_prizes'] ?? ['Rien', '10 Points', 'Boisson Gratuite', '50 Points', 'Burger Offert', 'Rien']),
    );
  }
}

final gamificationConfigProvider = StreamProvider<GamificationConfig>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('gamification')
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return GamificationConfig.fromMap(snapshot.data()!);
    } else {
      // Return default config
      return GamificationConfig(
        isWheelEnabled: false,
        wheelCost: 50,
        wheelPrizes: ['Rien', '10 Points', 'Boisson Gratuite', '50 Points', 'Burger Offert', 'Rien'],
      );
    }
  });
});

class GamificationActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateConfig(GamificationConfig config) async {
    await _firestore.collection('config').doc('gamification').set(config.toMap());
  }
}

final gamificationActionsProvider = Provider((ref) => GamificationActions());
