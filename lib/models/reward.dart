class RewardConfig {
  final double spendingPerPoint; // Example: 100 DA = 1 point
  final int pointsRequiredForReward; // Example: 100 points
  final String rewardDescription; // Example: "Un café gratuit"

  RewardConfig({
    required this.spendingPerPoint,
    required this.pointsRequiredForReward,
    required this.rewardDescription,
  });

  factory RewardConfig.fromMap(Map<String, dynamic> data) {
    return RewardConfig(
      spendingPerPoint: (data['spendingPerPoint'] ?? 10.0).toDouble(),
      pointsRequiredForReward: data['pointsRequiredForReward'] ?? 100,
      rewardDescription: data['rewardDescription'] ?? 'Cadeau Gratuit',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'spendingPerPoint': spendingPerPoint,
      'pointsRequiredForReward': pointsRequiredForReward,
      'rewardDescription': rewardDescription,
    };
  }
}
