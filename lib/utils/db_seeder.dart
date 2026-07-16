import 'package:cloud_firestore/cloud_firestore.dart';

class DbSeeder {
  static Future<void> seedDatabase() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Seed App Settings (Correct collection/doc: config/fastfood)
    await firestore.collection('config').doc('fastfood').set({
      'fastfood_name': 'Revo FastFood',
      'fastfood_description': 'Le meilleur fast-food de la ville avec des ingrédients frais et locaux !',
      'announcement_banner': 'Livraison gratuite à partir de 2000 DA !',
      'store_lat': 36.7525,
      'store_lng': 3.04197,
      'geofence_messages': [
        '👋 Vous êtes près de chez nous ! Passez au magasin pour découvrir nos nouveautés !',
        '🍔 Une faim de loup ? Notre fast-food est juste à côté !',
        '🎁 Venez récupérer vos points de fidélité en magasin !'
      ],
    }, SetOptions(merge: true));

    // 2. Seed Categories (Correct collection/doc: config/categories)
    final categoryNames = ['Burgers', 'Tacos', 'Pizzas', 'Boissons', 'Desserts'];
    await firestore.collection('config').doc('categories').set({
      'list': categoryNames,
    }, SetOptions(merge: true));

    // 3. Clear existing products first to avoid duplicates (optional but good for clean start)
    final existingProducts = await firestore.collection('products').get();
    for (var doc in existingProducts.docs) {
      await doc.reference.delete();
    }

    // 4. Seed Menu Items (Correct collection: products)
    final menuItems = [
      // Burgers
      {
        'name': 'Cheese Burger Classique',
        'description': 'Steak haché pur bœuf 150g, double cheddar affiné, salade, tomate, oignons, sauce maison.',
        'price': 450.0,
        'category': 'Burgers',
        'imageUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Le Montagnard',
        'description': 'Steak haché 150g, fromage à raclette fondu, bacon croustillant, oignons caramélisés.',
        'price': 600.0,
        'category': 'Burgers',
        'imageUrl': 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Chicken Crispy',
        'description': 'Filet de poulet pané croustillant, salade iceberg, sauce mayonnaise.',
        'price': 500.0,
        'category': 'Burgers',
        'imageUrl': 'https://images.unsplash.com/photo-1615719413546-198b25453f85?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Tacos
      {
        'name': 'Tacos Viande Hachée',
        'description': 'Tacos taille L, viande hachée, frites croustillantes, sauce fromagère.',
        'price': 500.0,
        'category': 'Tacos',
        'imageUrl': 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Tacos Poulet',
        'description': 'Tacos taille L, escalope de poulet marinée, frites, sauce algérienne.',
        'price': 500.0,
        'category': 'Tacos',
        'imageUrl': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Tacos Mixte (XL)',
        'description': 'Tacos taille XL, viande hachée et poulet, double portion de frites.',
        'price': 700.0,
        'category': 'Tacos',
        'imageUrl': 'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Pizzas
      {
        'name': 'Pizza Margherita',
        'description': 'Sauce tomate maison, mozzarella fondante, basilic frais.',
        'price': 400.0,
        'category': 'Pizzas',
        'imageUrl': 'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Pizza 4 Fromages',
        'description': 'Crème fraîche, mozzarella, chèvre, emmental, gorgonzola.',
        'price': 700.0,
        'category': 'Pizzas',
        'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Boissons
      {
        'name': 'Coca-Cola (33cl)',
        'description': 'Canette bien fraîche.',
        'price': 100.0,
        'category': 'Boissons',
        'imageUrl': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'name': 'Sprite (33cl)',
        'description': 'Canette bien fraîche.',
        'price': 100.0,
        'category': 'Boissons',
        'imageUrl': 'https://images.unsplash.com/photo-1625772299848-391b6a51d45f?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Desserts
      {
        'name': 'Tiramisu Maison',
        'description': 'Véritable Tiramisu italien préparé le jour même.',
        'price': 350.0,
        'category': 'Desserts',
        'imageUrl': 'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
    ];

    for (var prod in menuItems) {
      await firestore.collection('products').add({
        'name': prod['name'],
        'description': prod['description'],
        'price': prod['price'],
        'category': prod['category'],
        'imageUrl': prod['imageUrl'],
        'is_available': prod['is_available'],
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
}
