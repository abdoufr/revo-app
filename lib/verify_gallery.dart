import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final snapshot = await FirebaseFirestore.instance.collection('products').limit(5).get();
  for (var doc in snapshot.docs) {
    print('Product: ${doc.data()['name']}');
    final gallery = doc.data()['gallery'];
    print('Gallery: ${gallery != null ? (gallery as List).length : 0} images');
  }
}
