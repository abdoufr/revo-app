import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/product.dart';

class AdminMenuScreen extends ConsumerWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer le Menu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddProductDialog(context, ref);
        },
        backgroundColor: AppTheme.accentCyan,
        icon: const Icon(Icons.add, color: AppTheme.bgDark),
        label: const Text('Nouveau Produit', style: TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.bold)),
      ),
      body: productsAsyncValue.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Aucun produit dans le menu.', style: TextStyle(color: AppTheme.textGrey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgLighter,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('${product.price} DA', style: const TextStyle(color: AppTheme.accentCyan)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.textGrey),
                        onPressed: () {
                          _showAddProductDialog(context, ref, product: product);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(adminActionsProvider).deleteProduct(product.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgLighter,
          title: Text(product == null ? 'Ajouter Produit' : 'Modifier Produit', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Nom du produit'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Description'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Prix (DA)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newProduct = Product(
                  id: product?.id ?? '',
                  name: nameController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  category: 'General',
                );
                
                if (product == null) {
                  ref.read(adminActionsProvider).addProduct(newProduct);
                } else {
                  ref.read(adminActionsProvider).updateProduct(newProduct);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
              child: const Text('Enregistrer', style: TextStyle(color: AppTheme.bgDark)),
            ),
          ],
        );
      },
    );
  }
}
