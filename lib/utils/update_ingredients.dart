import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateIngredientsSeeder {
  static Future<void> update() async {
    final firestore = FirebaseFirestore.instance;
    
    // First, clear existing extra ingredients
    final ingredientsSnapshot = await firestore.collection('ingredients').get();
    for (var doc in ingredientsSnapshot.docs) {
      await doc.reference.delete();
    }

    final extras = [
      {
        'name': 'Cheddar',
        'price': 200.0,
        'categories': ['pizza', 'tacos', 'sandwich', 'cheese'],
      },
      {
        'name': 'Viande Hachée',
        'price': 250.0,
        'categories': ['pizza', 'tacos', 'sandwich'],
      },
      {
        'name': 'Poulet',
        'price': 200.0,
        'categories': ['pizza', 'tacos', 'sandwich'],
      },
      {
        'name': 'Sauce Fromagère',
        'price': 100.0,
        'categories': ['tacos', 'sandwich', 'cheese'],
      },
      {
        'name': 'Frites',
        'price': 100.0,
        'categories': ['tacos', 'sandwich'],
      },
      {
        'name': 'Olives',
        'price': 50.0,
        'categories': ['pizza', 'sandwich'],
      },
      {
        'name': 'Champignons',
        'price': 100.0,
        'categories': ['pizza', 'tacos', 'sandwich'],
      },
      {
        'name': 'Mozzarella',
        'price': 200.0,
        'categories': ['pizza', 'cheese'],
      },
      {
        'name': 'Oeuf',
        'price': 50.0,
        'categories': ['pizza', 'tacos', 'sandwich'],
      },
      {
        'name': 'Thon',
        'price': 150.0,
        'categories': ['pizza', 'sandwich'],
      },
      {
        'name': 'Merguez',
        'price': 200.0,
        'categories': ['pizza', 'sandwich'],
      },
    ];

    for (var extra in extras) {
      await firestore.collection('ingredients').add({
        'name': extra['name'],
        'price': extra['price'],
        'categories': extra['categories'],
        'is_available': true,
        'image_url': '',
      });
    }
  }
}
