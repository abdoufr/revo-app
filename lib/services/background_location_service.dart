import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tâche en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kIsWeb) return Future.value(true);
    try {
      await BackgroundLocationService.checkLocationAndNotify();
    } catch (e) {
      debugPrint("Background task error: $e");
    }
    return Future.value(true);
  });
}

class BackgroundLocationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Timer? _webTimer;

  static Future<void> checkLocationAndNotify() async {
    // 1. Initialiser Firebase si nécessaire
    try {
      await Firebase.initializeApp();
    } catch(e) {
      // Déjà initialisé
    }

    // 2. Vérifier les permissions de localisation
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    // 3. Obtenir la position actuelle
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // 4. Obtenir les paramètres du magasin depuis Firebase
    final doc = await FirebaseFirestore.instance.collection('config').doc('fastfood').get();
    if (!doc.exists || doc.data() == null) return;

    final data = doc.data()!;
    final double storeLat = (data['storeLat'] ?? 0.0).toDouble();
    final double storeLng = (data['storeLng'] ?? 0.0).toDouble();
    final double radius = (data['geofenceRadius'] ?? 100.0).toDouble();
    final List<String> messages = List<String>.from(data['geofenceMessages'] ?? ['Vous êtes à côté !']);

    if (storeLat == 0.0 && storeLng == 0.0) return;

    // 5. Calculer la distance
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      storeLat,
      storeLng,
    );

    // 6. Vérifier si l'utilisateur est dans le rayon
    if (distanceInMeters <= radius) {
      final prefs = await SharedPreferences.getInstance();
      final lastChecked = prefs.getInt('last_geofence_notification') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Limite : 1 notification par 24h
      if (now - lastChecked > 86400000) {
        await prefs.setInt('last_geofence_notification', now);
        
        final randomMessage = messages[Random().nextInt(messages.length)];
        await BackgroundLocationService.showNotification(randomMessage);
      }
    }
  }

  static Future<void> init() async {
    // Initialiser les notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    if (kIsWeb) {
      // Sur le Web on lance un timer au lieu du WorkManager
      _webTimer?.cancel();
      _webTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
        try {
          await checkLocationAndNotify();
        } catch (e) {
          debugPrint("Web timer error: $e");
        }
      });
      return; 
    }

    // Demander la permission sur Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Initialiser WorkManager (Android/iOS seulement)
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Enregistrer la tâche périodique (15 minutes minimum)
    Workmanager().registerPeriodicTask(
      "1",
      "geofence_check",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected, // Nécessaire pour fetch Firebase
      ),
    );
  }

  static Future<void> showNotification(String message, {String title = 'Vous êtes tout près ! 🍔'}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'geofence_channel', 
      'Notifications de proximité',
      channelDescription: 'Notifications lorsque vous êtes proche de notre magasin',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
