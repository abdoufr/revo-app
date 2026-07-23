class ClaimedReward {
  final String id;
  final String userId;
  final String rewardTitle;
  final String source;
  final String status;
  final DateTime createdAt;
  final DateTime? claimedAt;

  ClaimedReward({
    required this.id,
    required this.userId,
    required this.rewardTitle,
    required this.source,
    required this.status,
    required this.createdAt,
    this.claimedAt,
  });

  factory ClaimedReward.fromMap(String id, Map<String, dynamic> data) {
    return ClaimedReward(
      id: id,
      userId: data['userId'] ?? '',
      rewardTitle: data['rewardTitle'] ?? 'Cadeau',
      source: data['source'] ?? 'boutique',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      claimedAt: data['claimedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['claimedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rewardTitle': rewardTitle,
      'source': source,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'claimedAt': claimedAt?.millisecondsSinceEpoch,
    };
  }
}
