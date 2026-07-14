import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:geofence_service/geofence_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GeofenceService {
  static Future<void> checkLocationAndNotify(
    BuildContext context,
    double storeLat,
    double storeLng,
    List<String> messages,
  ) async {
    // Only check once per day to not annoy the user
    final prefs = await SharedPreferences.getInstance();
    final lastChecked = prefs.getInt('last_geofence_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 24 hours cooldown
    if (now - lastChecked < 86400000) {
      return;
    }

    if (storeLat == 0.0 && storeLng == 0.0) return; // Not set

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Localisation désactivée',
          'Veuillez activer le GPS pour recevoir nos offres lorsque vous passez près du magasin !',
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          _showPermissionDialog(
            context,
            'Permission refusée',
            'L\'application a besoin de la localisation pour savoir si vous êtes à proximité de notre fastfood. Vous ratez des cadeaux !',
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permission bloquée',
          'Vous avez bloqué la localisation de manière permanente. Allez dans les paramètres de votre appareil pour l\'activer et profiter de nos cadeaux de proximité.',
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        storeLat,
        storeLng,
      );

      // 100 meters
      if (distanceInMeters <= 100) {
        await prefs.setInt('last_geofence_check', now);

        if (context.mounted && messages.isNotEmpty) {
          final randomMessage = messages[Random().nextInt(messages.length)];
          _showBanner(context, randomMessage);
        }
      }
    } catch (e) {
      // Ignore location errors silently for the user
      debugPrint('Geofence error: $e');
    }
  }

  static void _showBanner(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 30),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Vous êtes tout près !',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF5722),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.location_disabled_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'COMPRIS',
              style: TextStyle(
                color: Color(0xFFFF5722),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TRUE BACKGROUND GEOFENCING IMPLEMENTATION
// ==========================================

// This function is to be called when the geofence status changes in background.
@pragma('vm:entry-point')
void geofenceTaskHandler() {
  GeofenceService.instance.execute(GeofenceTaskHandler());
}

class GeofenceTaskHandler extends GeofenceTaskCallback {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  GeofenceTaskHandler() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(0, title, body, details);
  }

  @override
  void onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) {
    debugPrint('Geofence: ${geofence.id}, Status: $geofenceStatus');

    if (geofenceStatus == GeofenceStatus.ENTER) {
      _showNotification(
        "👋 Vous êtes près de chez nous !",
        "Passez au magasin pour découvrir nos nouveautés !",
      );
    }
  }

  @override
  void onActivityChanged(Activity prevActivity, Activity currActivity) {}

  @override
  void onLocationChanged(Location location) {}

  @override
  void onLocationServicesStatusChanged(bool status) {}

  @override
  void onError(GeofenceServiceError error) {
    debugPrint('Geofence Error: $error');
  }
}

class GeofencingServiceManager {
  static final GeofencingServiceManager _instance =
      GeofencingServiceManager._internal();
  factory GeofencingServiceManager() => _instance;
  GeofencingServiceManager._internal();

  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  Future<void> startGeofencing(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0) return;

    final geofenceList = <Geofence>[
      Geofence(
        id: 'shop_1',
        latitude: lat,
        longitude: lng,
        radius: [GeofenceRadius(id: 'radius_500m', length: 500)],
      ),
    ];

    try {
      await _geofenceService.start(geofenceList).catchError((e) {
        debugPrint('Erreur de démarrage Geofence: $e');
      });
      _geofenceService.addGeofenceStatusChangeListener((
        geofence,
        geofenceRadius,
        geofenceStatus,
        location,
      ) {
        debugPrint('Foreground Geofence: $geofenceStatus');
      });
    } catch (e) {
      debugPrint('Geofence Setup Error: $e');
    }
  }

  void stopGeofencing() {
    _geofenceService.stop();
  }
}
