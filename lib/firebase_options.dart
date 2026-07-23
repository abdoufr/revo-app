import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNAZn0fXq2Yz9eJAgWqzX_uP7ax_C1P4A',
    appId: '1:984076605218:web:b4f45561dcd8fe68aeb77b',
    messagingSenderId: '984076605218',
    projectId: 'revo-app-16462',
    authDomain: 'revo-app-16462.firebaseapp.com',
    storageBucket: 'revo-app-16462.firebasestorage.app',
    measurementId: 'G-Z094F3VM59',
  );

  // We are using the web config for Android/iOS temporarily as fallback if google-services.json is missing,
  // but typically Android requires its own app ID.
  // For simplicity since the user only generated a web app, we'll try to use it across,
  // but normally they need to register an Android app. We will just use the web options for now.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtaVXK2Pxms8Y3p_I2ZKvRJR4T9eHxicM',
    appId: '1:984076605218:android:265236c2635e57a0aeb77b',
    messagingSenderId: '984076605218',
    projectId: 'revo-app-16462',
    authDomain: 'revo-app-16462.firebaseapp.com',
    storageBucket: 'revo-app-16462.firebasestorage.app',
    measurementId: 'G-Z094F3VM59',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNAZn0fXq2Yz9eJAgWqzX_uP7ax_C1P4A',
    appId: '1:984076605218:web:b4f45561dcd8fe68aeb77b',
    messagingSenderId: '984076605218',
    projectId: 'revo-app-16462',
    authDomain: 'revo-app-16462.firebaseapp.com',
    storageBucket: 'revo-app-16462.firebasestorage.app',
    measurementId: 'G-Z094F3VM59',
  );
}
