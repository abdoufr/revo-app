import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/update_ingredients.dart';

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
  String status = "Mise à jour des ingrédients...";

  @override
  void initState() {
    super.initState();
    _runSeeder();
  }

  Future<void> _runSeeder() async {
    try {
      await UpdateIngredientsSeeder.update();
      setState(() {
        status = "✅ SUCCÈS ! Les ingrédients ont été ajoutés !";
      });
      print("INGREDIENTS_SUCCESS_123");
    } catch (e) {
      setState(() {
        status = "❌ ERREUR : $e";
      });
      print("INGREDIENTS_ERROR: $e");
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
