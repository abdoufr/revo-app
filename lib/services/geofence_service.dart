import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceService {
  static Future<void> requestBackgroundPermission(BuildContext context) async {
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
            'L\'application a besoin de la localisation pour vous avertir lorsque vous êtes à proximité de notre fastfood.'
          );
        }
        return;
      }
    }
    
    // Pour Android 10+ et iOS, on doit demander "Always" pour l'arrière-plan
    // Requis pour le "Plan B" (Foreground Service) pour une réactivité maximale
    if (permission == LocationPermission.whileInUse) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'GPS en continu (Plan B)',
          'Pour que l\'application puisse détecter le magasin à la seconde près même quand elle est fermée, veuillez choisir "Toujours autoriser" dans les paramètres.'
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permission bloquée',
          'Vous avez bloqué la localisation de manière permanente. Allez dans les paramètres de votre appareil pour l\'activer et profiter de nos alertes de proximité.'
        );
      }
      return;
    }
  }

  static void _showPermissionDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Ouvrir Paramètres'),
          ),
        ],
      ),
    );
  }
}

