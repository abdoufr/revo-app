import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ingredient.dart';

final ingredientsProvider = StreamProvider<List<Ingredient>>((ref) {
  return FirebaseFirestore.instance
      .collection('ingredients')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Ingredient.fromMap(doc.data(), doc.id))
        .toList();
  });
});

// Provider filtered by category for the composer
final ingredientsByCategoryProvider = StreamProvider.family<List<Ingredient>, String>((ref, category) {
  return FirebaseFirestore.instance
      .collection('ingredients')
      .where('categories', arrayContains: category)
      .where('is_available', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Ingredient.fromMap(doc.data(), doc.id))
        .toList();
  });
});

class IngredientActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addIngredient(Ingredient ingredient) async {
    await _firestore.collection('ingredients').add(ingredient.toMap());
  }

  Future<void> deleteIngredient(String id) async {
    await _firestore.collection('ingredients').doc(id).delete();
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await _firestore.collection('ingredients').doc(id).update({'is_available': isAvailable});
  }
}

final ingredientActionsProvider = Provider((ref) => IngredientActions());
