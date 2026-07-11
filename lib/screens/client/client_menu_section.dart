import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_translations.dart';
import 'product_reviews_sheet.dart';

class ClientMenuSection extends StatefulWidget {
  final List<Product> products;

  const ClientMenuSection({super.key, required this.products});

  @override
  State<ClientMenuSection> createState() => _ClientMenuSectionState();
}

class _ClientMenuSectionState extends State<ClientMenuSection> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    // 1. Extract unique categories
    final categories = ['All'];
    for (var p in widget.products) {
      if (p.category.isNotEmpty && !categories.contains(p.category)) {
        categories.add(p.category);
      }
    }

    // 2. Filter products
    final filteredProducts = widget.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'search_menu'.tr(context),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryOrange),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 16),

        // Categories Chips
        if (categories.length > 1)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                final displayCategory = category == 'All' ? 'all_categories'.tr(context) : category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      displayCategory,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryOrange,
                    backgroundColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),

        // Products List
        if (filteredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'empty_menu'.tr(context),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Opacity(
                  opacity: product.isAvailable ? 1.0 : 0.6,
                  child: SoftCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => showProductReviews(context, product),
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: product.imageUrl != null && product.imageUrl!.startsWith('data:image')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  base64Decode(product.imageUrl!.split(',').last),
                                  fit: BoxFit.cover,
                                  color: product.isAvailable ? null : Colors.black.withOpacity(0.5),
                                  colorBlendMode: product.isAvailable ? null : BlendMode.darken,
                                ),
                              )
                            : Icon(Icons.fastfood, color: product.isAvailable ? AppTheme.primaryOrange : Colors.grey),
                      ),
                      title: Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: product.isAvailable ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          product.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: product.isAvailable ? null : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!product.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Indisponible',
                                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            Text(
                              '${product.price} DA',
                              style: const TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
