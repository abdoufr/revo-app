import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'product_details_screen.dart';

class ClientFullListScreen extends StatelessWidget {
  final String title;
  final List<Product> products;

  const ClientFullListScreen({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: products.isEmpty
          ? Center(
              child: Text(
                'Aucun produit disponible.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildGridItem(context, product);
              },
            ),
    );
  }

  Widget _buildGridItem(BuildContext context, Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (product.isAvailable) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        }
      },
      child: Opacity(
        opacity: product.isAvailable ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: product.imageUrl != null && product.imageUrl!.startsWith('data:image')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.memory(
                                base64Decode(product.imageUrl!.split(',').last),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.isEmpty ? 'General' : product.category,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${product.price.toStringAsFixed(1)} DA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
