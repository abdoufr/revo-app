import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final snapshot = await FirebaseFirestore.instance.collection('products').limit(3).get();
  for (var doc in snapshot.docs) {
    print('PRODUCT ID: ${doc.id}');
    print('RAW DATA KEYS: ${doc.data().keys}');
    print('gallery key exists? ${doc.data().containsKey('gallery')}');
    print('gallery content: ${doc.data()['gallery']}');
    print('----------------');
  }
}
