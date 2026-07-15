import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DbSeeder {
  static Future<void> seedDatabase() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Seed App Settings
    await firestore.collection('settings').doc('app_settings').set({
      'fastfood_name': 'Revo FastFood',
      'fastfood_description':
          'Le meilleur fast-food de la ville avec des ingrédients frais et locaux !',
      'announcement_banner': 'Livraison gratuite à partir de 2000 DA !',
      'store_lat': 36.7525,
      'store_lng': 3.04197,
      'geofence_messages': [
        '👋 Vous êtes près de chez nous ! Passez au magasin pour découvrir nos nouveautés !',
        '🍔 Une faim de loup ? Notre fast-food est juste à côté !',
        '🎁 Venez récupérer vos points de fidélité en magasin !',
      ],
    }, SetOptions(merge: true));

    // 2. Seed Categories
    final categories = [
      {'id': 'cat_burgers', 'name': 'Burgers', 'icon': '🍔', 'order': 1},
      {'id': 'cat_tacos', 'name': 'Tacos', 'icon': '🌯', 'order': 2},
      {'id': 'cat_pizzas', 'name': 'Pizzas', 'icon': '🍕', 'order': 3},
      {'id': 'cat_boissons', 'name': 'Boissons', 'icon': '🥤', 'order': 4},
      {'id': 'cat_desserts', 'name': 'Desserts', 'icon': '🍨', 'order': 5},
    ];

    for (var cat in categories) {
      await firestore.collection('categories').doc(cat['id'] as String).set({
        'name': cat['name'],
        'icon': cat['icon'],
        'order': cat['order'],
      }, SetOptions(merge: true));
    }

    // 3. Seed Menu Items
    final menuItems = [
      // Burgers
      {
        'id': 'prod_burger_1',
        'name': 'Cheese Burger Classique',
        'description':
            'Steak haché pur bœuf 150g, double cheddar affiné, salade, tomate, oignons, sauce maison.',
        'price': 450.0,
        'category_id': 'cat_burgers',
        'image_url':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_burger_2',
        'name': 'Le Montagnard',
        'description':
            'Steak haché 150g, fromage à raclette fondu, bacon croustillant, oignons caramélisés.',
        'price': 600.0,
        'category_id': 'cat_burgers',
        'image_url':
            'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_burger_3',
        'name': 'Chicken Crispy',
        'description':
            'Filet de poulet pané croustillant, salade iceberg, sauce mayonnaise légèrement poivrée.',
        'price': 500.0,
        'category_id': 'cat_burgers',
        'image_url':
            'https://images.unsplash.com/photo-1615719413546-198b25453f85?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Tacos
      {
        'id': 'prod_tacos_1',
        'name': 'Tacos Viande Hachée',
        'description':
            'Tacos taille L, viande hachée assaisonnée, frites croustillantes, sauce fromagère maison.',
        'price': 500.0,
        'category_id': 'cat_tacos',
        'image_url':
            'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_tacos_2',
        'name': 'Tacos Poulet',
        'description':
            'Tacos taille L, escalope de poulet marinée au curry, frites, sauce algérienne.',
        'price': 500.0,
        'category_id': 'cat_tacos',
        'image_url':
            'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_tacos_3',
        'name': 'Tacos Mixte (XL)',
        'description':
            'Tacos taille XL, viande hachée et poulet, double portion de frites, supplément gruyère.',
        'price': 700.0,
        'category_id': 'cat_tacos',
        'image_url':
            'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Pizzas
      {
        'id': 'prod_pizza_1',
        'name': 'Pizza Margherita',
        'description':
            'Sauce tomate maison, mozzarella fondante, basilic frais, filet d\'huile d\'olive.',
        'price': 400.0,
        'category_id': 'cat_pizzas',
        'image_url':
            'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_pizza_2',
        'name': 'Pizza 4 Fromages',
        'description':
            'Crème fraîche, mozzarella, chèvre, emmental, gorgonzola.',
        'price': 700.0,
        'category_id': 'cat_pizzas',
        'image_url':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_pizza_3',
        'name': 'Pizza Orientale',
        'description':
            'Sauce tomate, mozzarella, viande hachée, poivrons, oignons, olives noires.',
        'price': 650.0,
        'category_id': 'cat_pizzas',
        'image_url':
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Boissons
      {
        'id': 'prod_boisson_1',
        'name': 'Coca-Cola (33cl)',
        'description': 'Canette bien fraîche de Coca-Cola.',
        'price': 100.0,
        'category_id': 'cat_boissons',
        'image_url':
            'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_boisson_2',
        'name': 'Sprite (33cl)',
        'description': 'Canette bien fraîche de Sprite.',
        'price': 100.0,
        'category_id': 'cat_boissons',
        'image_url':
            'https://images.unsplash.com/photo-1625772299848-391b6a51d45f?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_boisson_3',
        'name': 'Eau Minérale (50cl)',
        'description': 'Bouteille d\'eau minérale plate froide.',
        'price': 50.0,
        'category_id': 'cat_boissons',
        'image_url':
            'https://images.unsplash.com/photo-1548839140-29a749e1abc4?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      // Desserts
      {
        'id': 'prod_dessert_1',
        'name': 'Tiramisu Maison',
        'description':
            'Véritable Tiramisu italien préparé le jour même au café et mascarpone.',
        'price': 350.0,
        'category_id': 'cat_desserts',
        'image_url':
            'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
      {
        'id': 'prod_dessert_2',
        'name': 'Cheesecake Fraise',
        'description': 'Cheesecake onctueux avec un coulis de fraise parfumé.',
        'price': 400.0,
        'category_id': 'cat_desserts',
        'image_url':
            'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=800&q=80',
        'is_available': true,
      },
    ];

    for (var prod in menuItems) {
      await firestore.collection('menu').doc(prod['id'] as String).set({
        'name': prod['name'],
        'description': prod['description'],
        'price': prod['price'],
        'category_id': prod['category_id'],
        'image_url': prod['image_url'],
        'is_available': prod['is_available'],
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 4. Seed Rewards Catalog
    final rewards = [
      {
        'id': 'rew_burger_gratuit',
        'title': 'Burger Gratuit',
        'description':
            'Obtenez un Cheese Burger classique totalement gratuit !',
        'points_cost': 500,
        'image_url':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
        'is_active': true,
      },
      {
        'id': 'rew_boisson_gratuite',
        'title': 'Boisson Offerte',
        'description':
            'Une canette de votre choix offerte avec votre prochaine commande.',
        'points_cost': 150,
        'image_url':
            'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80',
        'is_active': true,
      },
      {
        'id': 'rew_remise_500',
        'title': 'Bon d\'achat 500 DA',
        'description':
            'Bénéficiez d\'une remise de 500 DA sur le total de votre prochaine commande.',
        'points_cost': 1000,
        'image_url':
            'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=800&q=80',
        'is_active': true,
      },
    ];

    for (var rew in rewards) {
      await firestore
          .collection('rewards_catalog')
          .doc(rew['id'] as String)
          .set({
            'title': rew['title'],
            'description': rew['description'],
            'points_cost': rew['points_cost'],
            'image_url': rew['image_url'],
            'is_active': rew['is_active'],
            'created_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }
}
