import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/db_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SeederApp());
}

class SeederApp extends StatefulWidget {
  const SeederApp({super.key});

  @override
  State<SeederApp> createState() => _SeederAppState();
}

class _SeederAppState extends State<SeederApp> {
  String status = "Démarrage du remplissage...";

  @override
  void initState() {
    super.initState();
    _runSeeder();
  }

  Future<void> _runSeeder() async {
    try {
      await DbSeeder.seedDatabase();
      setState(() {
        status = "✅ SUCCÈS ! La base de données a été remplie avec le Menu Réel et la Configuration ! Vous pouvez fermer cette fenêtre.";
      });
      print("SEEDER_SUCCESS_123");
    } catch (e) {
      setState(() {
        status = "❌ ERREUR : $e";
      });
      print("SEEDER_ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              status,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
