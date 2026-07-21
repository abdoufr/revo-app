import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return FirebaseFirestore.instance.collection('config').doc('fastfood').snapshots().map((doc) {
    if (doc.exists && doc.data() != null) {
      return AppSettings.fromMap(doc.data()!);
    }
    // Default settings
    return AppSettings(
      fastfoodName: 'REVO APP',
      fastfoodDescription: 'Le meilleur fastfood!',
      announcementBanner: '',
      storeLat: 0.0,
      storeLng: 0.0,
      geofenceRadius: 100.0,
      geofenceMessages: ['Vous êtes à côté ! Venez nous voir !'],
    );
  });
});
