class AppSettings {
  final String fastfoodName;
  final String fastfoodDescription;
  final String announcementBanner; // For the Promotions Banner

  AppSettings({
    required this.fastfoodName,
    required this.fastfoodDescription,
    required this.announcementBanner,
  });

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      fastfoodName: data['fastfoodName'] ?? 'Mon Fastfood',
      fastfoodDescription: data['fastfoodDescription'] ?? 'Le meilleur de la ville!',
      announcementBanner: data['announcementBanner'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fastfoodName': fastfoodName,
      'fastfoodDescription': fastfoodDescription,
      'announcementBanner': announcementBanner,
    };
  }
}
