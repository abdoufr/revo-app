class AppSettings {
  final String fastfoodName;
  final String fastfoodDescription;
  final String announcementBanner; // For the Promotions Banner
  final double storeLat;
  final double storeLng;
  final double geofenceRadius; // Detection radius in meters
  final List<String> geofenceMessages;

  AppSettings({
    required this.fastfoodName,
    required this.fastfoodDescription,
    required this.announcementBanner,
    required this.storeLat,
    required this.storeLng,
    required this.geofenceRadius,
    required this.geofenceMessages,
  });

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      fastfoodName: data['fastfoodName'] ?? 'Mon Fastfood',
      fastfoodDescription: data['fastfoodDescription'] ?? 'Le meilleur de la ville!',
      announcementBanner: data['announcementBanner'] ?? '',
      storeLat: (data['storeLat'] ?? 0.0).toDouble(),
      storeLng: (data['storeLng'] ?? 0.0).toDouble(),
      geofenceRadius: (data['geofenceRadius'] ?? 100.0).toDouble(),
      geofenceMessages: List<String>.from(data['geofenceMessages'] ?? ['Vous êtes à côté ! Venez nous voir !']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fastfoodName': fastfoodName,
      'fastfoodDescription': fastfoodDescription,
      'announcementBanner': announcementBanner,
      'storeLat': storeLat,
      'storeLng': storeLng,
      'geofenceRadius': geofenceRadius,
      'geofenceMessages': geofenceMessages,
    };
  }
}
