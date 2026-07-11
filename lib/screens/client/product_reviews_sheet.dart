import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/client_providers.dart';

class ProductReviewsSheet extends ConsumerStatefulWidget {
  final Product product;

  const ProductReviewsSheet({super.key, required this.product});

  @override
  ConsumerState<ProductReviewsSheet> createState() => _ProductReviewsSheetState();
}

class _ProductReviewsSheetState extends ConsumerState<ProductReviewsSheet> {
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview(String userId, String userName) async {
    if (_commentController.text.trim().isEmpty) return;

    await ref.read(reviewsActionsProvider).addReview(
      widget.product.id,
      userId,
      userName,
      _rating,
      _commentController.text.trim(),
    );

    _commentController.clear();
    setState(() {
      _rating = 5.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre avis !'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(productReviewsProvider(widget.product.id));
    final userAsync = ref.watch(clientUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header (Product Details)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.product.imageUrl != null && widget.product.imageUrl!.startsWith('data:image')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(base64Decode(widget.product.imageUrl!.split(',').last), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.fastfood, color: Theme.of(context).primaryColor, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${widget.product.price} DA', style: const TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      // Mock average rating (to do real: fetch from product if we add it, or calculate)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('Avis des clients', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Add Review Section
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Donner votre avis', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () => setState(() => _rating = index + 1.0),
                        );
                      }),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(hintText: 'C\'était délicieux !', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                          onPressed: () => _submitReview(user.id, user.name),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          
          const Divider(height: 1),

          // Reviews List
          Expanded(
            child: reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Center(child: Text('Aucun avis pour l\'instant. Soyez le premier !'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

void showProductReviews(BuildContext context, Product product) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50, bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ProductReviewsSheet(product: product),
    ),
  );
}
