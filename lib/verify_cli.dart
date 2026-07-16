import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final snapshot = await FirebaseFirestore.instance.collection('products').limit(5).get();
  for (var doc in snapshot.docs) {
    print('Product: ${doc.data()['name']}');
    final gallery = doc.data()['gallery'];
    print('Gallery size: ${gallery != null ? (gallery as List).length : 0} images');
  }
}
