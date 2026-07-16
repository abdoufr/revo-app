import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/client_providers.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/smart_image.dart';
import '../../services/storage_service.dart';

class ProductReviewsSheet extends ConsumerStatefulWidget {
  final Product product;
  final Review? existingReview;

  const ProductReviewsSheet({super.key, required this.product, this.existingReview});

  @override
  ConsumerState<ProductReviewsSheet> createState() => _ProductReviewsSheetState();
}

class _ProductReviewsSheetState extends ConsumerState<ProductReviewsSheet> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  List<String> _reviewImages = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _commentController.text = widget.existingReview!.comment;
      _rating = widget.existingReview!.rating;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(String userId, String userName) async {
    if (_commentController.text.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<String> finalImages = [];
      for (var img in _reviewImages) {
        if (img.startsWith('data:image')) {
          final url = await StorageService.uploadBase64Image(img, 'reviews');
          finalImages.add(url);
        } else {
          finalImages.add(img);
        }
      }

      await ref.read(reviewsActionsProvider).addReview(
        widget.product.id,
        userId,
        userName,
        _rating,
        _commentController.text.trim(),
        images: finalImages,
      );

      _commentController.clear();
      setState(() {
        _rating = 5.0;
        _reviewImages = [];
      });

      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre avis !'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
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
                  child: widget.product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SmartImage(widget.product.imageUrl!, fit: BoxFit.cover),
                        )
                      : Icon(Icons.fastfood, color: Theme.of(context).primaryColor, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${widget.product.price} DA', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
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
                    Text(
                      widget.existingReview != null ? 'Modifier votre avis' : 'Donner votre avis', 
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
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
                    if (_reviewImages.isNotEmpty)
                      Container(
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _reviewImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                          image: SmartImage.getProvider(_reviewImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _reviewImages.removeAt(index)),
                                    child: Container(
                                      color: Colors.white.withOpacity(0.8),
                                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_a_photo, color: Colors.grey),
                          onPressed: () async {
                            final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 400);
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              setState(() {
                                _reviewImages.add('data:image/jpeg;base64,' + base64Encode(bytes));
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(hintText: 'C\'était délicieux !', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
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
                                children: [
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  if (userAsync.value?.role == 'admin')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Supprimer l\'avis'),
                                            content: const Text('Voulez-vous vraiment supprimer cet avis ?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(reviewsActionsProvider).deleteReview(review.id, widget.product.id);
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
                          if (review.images.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.top(8),
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: review.images.length,
                                itemBuilder: (context, imgIndex) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: SmartImage.getProvider(review.images[imgIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
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