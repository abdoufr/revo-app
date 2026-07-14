import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class GeofenceService {
  static Future<void> checkLocationAndNotify(
    BuildContext context, 
    double storeLat, 
    double storeLng, 
    List<String> messages
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
          'Veuillez activer le GPS pour recevoir nos offres lorsque vous passez près du magasin !'
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
            'L\'application a besoin de la localisation pour savoir si vous êtes à proximité de notre fastfood. Vous ratez des cadeaux !'
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
          'Vous avez bloqué la localisation de manière permanente. Allez dans les paramètres de votre appareil pour l\'activer et profiter de nos cadeaux de proximité.'
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude, 
        position.longitude, 
        storeLat, 
        storeLng
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
            const Expanded(child: Text('Vous êtes tout près !', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_disabled_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('COMPRIS', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
