import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import 'product_reviews_sheet.dart'; // Just to re-use the review list if we want, or implement it here

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  bool _showDetails = true; // true = Details tab, false = Reviews tab

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Curved Red Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                        ),
                      ),
                      const Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Huge Image
                Hero(
                  tag: 'product_image_${widget.product.id}',
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: widget.product.imageUrl != null && widget.product.imageUrl!.startsWith('data:image')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(125),
                            child: Image.memory(base64Decode(widget.product.imageUrl!.split(',').last), fit: BoxFit.cover),
                          )
                        : const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.fastfood, size: 80, color: Colors.grey)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Content Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.name,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 28),
                              ),
                            ),
                            Text(
                              '${widget.product.price.toStringAsFixed(1)} DA',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Category Subtitle
                        Text(
                          widget.product.category.isEmpty ? 'General' : widget.product.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tabs (Details / Reviews)
                        Row(
                          children: [
                            _buildTabButton('Details', _showDetails),
                            const SizedBox(width: 16),
                            _buildTabButton('Reviews', !_showDetails),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tab Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: _showDetails 
                                ? _buildDetailsContent() 
                                : _buildReviewsContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      // Quantity Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() { if (_quantity > 1) _quantity--; }),
                              child: const Icon(Icons.remove, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Text('$_quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => setState(() => _quantity++),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // Add to Cart Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Add to cart logic here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${widget.product.name} ajouté au panier !'), backgroundColor: AppTheme.success),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = title == 'Details'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.description.isEmpty 
              ? 'Aucune description disponible pour ce produit. Il est cependant délicieux et préparé avec les meilleurs ingrédients !' 
              : widget.product.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: const Text('See more.', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildReviewsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Show old review bottom sheet
            showProductReviews(context, widget.product);
          },
          icon: const Icon(Icons.star, color: Colors.white),
          label: const Text('Ouvrir les avis complets', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
        ),
        const SizedBox(height: 16),
        Text('Les avis sont gérés dans l\'onglet dédié.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
