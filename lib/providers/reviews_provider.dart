import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool? isModified;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      productId: map['product_id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Anonyme',
      rating: (map['rating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isModified: map['is_modified'] as bool?,
    );
  }
}

// Provider pour obtenir les avis d'un produit spécifique
final productReviewsProvider = StreamProvider.family<List<Review>, String>((ref, productId) {
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('product_id', isEqualTo: productId)
      .snapshots()
      .map((snapshot) {
    final reviews = snapshot.docs.map((doc) => Review.fromMap(doc.data(), doc.id)).toList();
    // Tri côté client pour éviter l'index composite Firestore
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  });
});

class ReviewsActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview(String productId, String userId, String userName, double rating, String comment) async {
    // Vérifier si l'utilisateur a déjà laissé un avis pour ce produit
    final existingReviews = await _firestore
        .collection('reviews')
        .where('product_id', isEqualTo: productId)
        .where('user_id', isEqualTo: userId)
        .get();

    if (existingReviews.docs.isNotEmpty) {
      // Mettre à jour l'avis existant
      await existingReviews.docs.first.reference.update({
        'rating': rating,
        'comment': comment,
        'is_modified': true,
      });
    } else {
      // Créer un nouvel avis
      await _firestore.collection('reviews').add({
        'product_id': productId,
        'user_id': userId,
        'user_name': userName,
        'rating': rating,
        'comment': comment,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    
    // Mettre à jour la moyenne du produit (optionnel mais recommandé pour les perfs)
    _updateProductAverageRating(productId);
  }

  Future<void> deleteReview(String reviewId, String productId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
    _updateProductAverageRating(productId);
  }
  
  Future<void> _updateProductAverageRating(String productId) async {
    final allReviews = await _firestore.collection('reviews').where('product_id', isEqualTo: productId).get();
    if (allReviews.docs.isEmpty) return;
    
    double sum = 0;
    for (var doc in allReviews.docs) {
      sum += (doc.data()['rating'] ?? 5.0).toDouble();
    }
    double average = sum / allReviews.docs.length;
    
    await _firestore.collection('products').doc(productId).update({
      'rating': average,
      'reviews_count': allReviews.docs.length,
    });
  }
}

final reviewsActionsProvider = Provider((ref) => ReviewsActions());
