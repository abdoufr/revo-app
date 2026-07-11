import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_translations.dart';
import '../../providers/client_providers.dart';
import '../../providers/admin_providers.dart';
import '../../providers/admin_providers.dart';
import 'product_details_screen.dart'; // We'll create this next

class ClientMenuSection extends ConsumerStatefulWidget {
  final bool showFavoritesOnly;
  
  const ClientMenuSection({super.key, this.showFavoritesOnly = false});

  @override
  ConsumerState<ClientMenuSection> createState() => _ClientMenuSectionState();
}

class _ClientMenuSectionState extends ConsumerState<ClientMenuSection> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final favoriteIds = ref.watch(favoriteProductsProvider);

    return productsAsync.when(
      data: (products) {
        // 1. Extract unique categories
        final categories = ['All'];
        for (var p in products) {
          if (p.category.isNotEmpty && !categories.contains(p.category)) {
            categories.add(p.category);
          }
        }

        // 2. Filter products
        final filteredProducts = products.where((p) {
          bool matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                p.description.toLowerCase().contains(_searchQuery.toLowerCase());
          bool matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
          bool matchesFavorites = !widget.showFavoritesOnly || favoriteIds.contains(p.id);
          return matchesSearch && matchesCategory && matchesFavorites;
        }).toList();

        final popularProducts = filteredProducts.take(4).toList(); // Just a sample for "Popular"
        final nearestProducts = filteredProducts.skip(4).take(4).toList(); // Just a sample for "Nearest"

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Popular Food Section
            _buildSectionHeader('Popular Food'),
            const SizedBox(height: 16),
            _buildHorizontalList(popularProducts.isNotEmpty ? popularProducts : filteredProducts),

            const SizedBox(height: 32),

            // Nearest Section (or second row)
            if (nearestProducts.isNotEmpty) ...[
              _buildSectionHeader('Nearest'),
              const SizedBox(height: 16),
              _buildHorizontalList(nearestProducts),
            ],
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryRed))),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('See All', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildHorizontalList(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Aucun produit trouvé.', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoriteIds = ref.watch(favoriteProductsProvider);
    return GestureDetector(
      onTap: () {
        if (product.isAvailable) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)));
        }
      },
      child: Opacity(
        opacity: product.isAvailable ? 1.0 : 0.5,
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16, bottom: 8, top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Center(
                      child: Container(
                        height: 90,
                        width: 90,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: product.imageUrl != null && product.imageUrl!.startsWith('data:image')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.memory(base64Decode(product.imageUrl!.split(',').last), fit: BoxFit.cover),
                              )
                            : const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                      ),
                    ),
                    const Spacer(),
                    
                    // Title
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    
                    // Subtitle / Category
                    Text(
                      product.category.isEmpty ? 'General' : product.category,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price 
                    Text(
                      '${product.price.toStringAsFixed(1)} DA',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              
              // Favorite Icon
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoriteProductsProvider.notifier).toggle(product.id);
                  },
                  child: Icon(
                    favoriteIds.contains(product.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                    color: favoriteIds.contains(product.id) ? AppTheme.primaryRed : (isDark ? Colors.white54 : Colors.grey), 
                    size: 20
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
