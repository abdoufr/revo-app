import 'dart:ui';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'web_notification_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final notification = message.notification;
  if (notification != null) {
    await BackgroundLocationService.showNotification(
      notification.body ?? '',
      title: notification.title ?? 'Nouvelle Notification 🔔',
    );
  }
}

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
  static StreamSubscription? _announcementsSubscription;
  static DateTime? _initTime;

  static void listenToAnnouncements() {
    _announcementsSubscription?.cancel();
    _initTime = DateTime.now();

    _announcementsSubscription = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('created_at', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final createdAt = (data['created_at'] as Timestamp?)?.toDate();
            if (createdAt == null || (_initTime != null && createdAt.isAfter(_initTime!))) {
              final title = data['title'] as String? ?? 'Nouvelle Notification 🔔';
              final message = data['message'] as String? ?? '';
              if (message.isNotEmpty) {
                showNotification(message, title: title);
              }
            }
          }
        }
      }
    }, onError: (e) {
      debugPrint("Announcements stream error: $e");
    });
  }

  static Future<void> checkLocationAndNotify() async {
    // 1. Initialiser Firebase si nécessaire
    try {
      await Firebase.initializeApp();
    } catch(e) {
      // Déjà initialisé
    }

    // Check for new announcements in background
    try {
      final annSnapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();
      
      final prefs = await SharedPreferences.getInstance();
      List<String> seenIds = prefs.getStringList('seen_announcements') ?? [];

      for (var doc in annSnapshot.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          final data = doc.data();
          final title = data['title'] as String? ?? 'Nouvelle Notification 🔔';
          final message = data['message'] as String? ?? '';
          if (message.isNotEmpty) {
            await showNotification(message, title: title);
          }
        }
      }
      if (seenIds.length > 20) seenIds = seenIds.sublist(seenIds.length - 20);
      await prefs.setStringList('seen_announcements', seenIds);
    } catch (e) {
      debugPrint("Background announcement check error: $e");
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
    
    debugPrint("Geofence Check: User at (${position.latitude}, ${position.longitude})");
    debugPrint("Geofence Check: Store at ($storeLat, $storeLng)");
    debugPrint("Geofence Check: Distance = $distanceInMeters meters (Radius: $radius meters)");

    // 6. Vérifier si l'utilisateur est dans le rayon
    if (distanceInMeters <= radius) {
      final prefs = await SharedPreferences.getInstance();
      final lastChecked = prefs.getInt('last_geofence_notification') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Limite pour les tests : 1 minute (60000 ms)
      if (now - lastChecked > 60000) {
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

    // Demander la permission et créer le canal sur Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'announcements_channel',
        'Notifications & Annonces',
        description: 'Canal pour recevoir les annonces du fastfood',
        importance: Importance.max,
        playSound: true,
      );
      await androidImplementation.createNotificationChannel(channel);
    }

    // Démarrer l'écoute temps réel des annonces
    listenToAnnouncements();

    if (!kIsWeb) {
      try {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await messaging.subscribeToTopic('all_users');
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showNotification(
              notification.body ?? '',
              title: notification.title ?? 'Nouvelle Notification 🔔',
            );
          }
        });
      } catch (e) {
        debugPrint("FCM setup error: $e");
      }
    }

    if (kIsWeb) {
      requestWebNotificationPermission();
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

    // Initialiser le Foreground Service (Plan B)
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'announcements_channel',
        initialNotificationTitle: 'Revo App',
        initialNotificationContent: 'Localisation active (Plan B)',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundServiceStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> showNotification(String message, {String title = 'Vous êtes tout près ! 🍔'}) async {
    if (kIsWeb) {
      showWebNotification(title, message);
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'announcements_channel', 
      'Notifications & Annonces',
      channelDescription: 'Canal pour recevoir les annonces du fastfood',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
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

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error in isolate: $e");
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Vérifier la position toutes les 60 secondes en arrière-plan
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    try {
      await BackgroundLocationService.checkLocationAndNotify();
    } catch (e) {
      debugPrint("Foreground service check error: $e");
    }
  });
}
