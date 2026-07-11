import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/product.dart';
import '../../l10n/app_translations.dart';

class AdminMenuScreen extends ConsumerWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(productsStreamProvider);
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    final List<String> availableCategories = categoriesAsyncValue.value ?? ['General'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer le Menu', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddProductDialog(context, ref, availableCategories);
        },
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau Produit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: productsAsyncValue.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(child: Text('Aucun produit dans le menu.', style: Theme.of(context).textTheme.bodyMedium));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(product.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('${product.price} DA', style: const TextStyle(color: AppTheme.primaryRed)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: product.isAvailable,
                          activeColor: AppTheme.primaryRed,
                          onChanged: (val) {
                            ref.read(adminActionsProvider).toggleProductAvailability(product.id, val);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
                          onPressed: () {
                            _showAddProductDialog(context, ref, availableCategories, product: product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () {
                            ref.read(adminActionsProvider).deleteProduct(product.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, List<String> categories, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    
    String selectedCategory = product?.category ?? '';
    if (selectedCategory.isNotEmpty && !categories.contains(selectedCategory)) {
      categories = [...categories, selectedCategory];
    }
    if (selectedCategory.isEmpty || !categories.contains(selectedCategory)) {
      selectedCategory = categories.isNotEmpty ? categories.first : 'General';
    }
    if (!categories.contains('General') && categories.isEmpty) {
        categories = ['General'];
        selectedCategory = 'General';
    }
    String? base64Image = product?.imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(product == null ? 'Ajouter Produit' : 'Modifier Produit', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker Section
                    GestureDetector(
                      onTap: () async {
                        try {
                          final picker = _getPicker(); // Will import image_picker
                          final pickedFile = await picker.pickImage(source: _getImageSource(), maxWidth: 800, imageQuality: 85);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            // We import dart:convert at the top of file
                            final base64String = 'data:image/jpeg;base64,' + _base64Encode(bytes);
                            setState(() {
                              base64Image = base64String;
                            });
                          }
                        } catch (e) {
                          // Handle error
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryRed, width: 1, style: BorderStyle.solid),
                        ),
                        child: base64Image != null && base64Image!.startsWith('data:image')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  _decodeBase64(base64Image!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryRed, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ajouter une image',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(hintText: 'Nom du produit'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(hintText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(hintText: 'Prix (DA)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'category'.tr(context),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: Theme.of(context).textTheme.bodyMedium),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newProduct = Product(
                      id: product?.id ?? '',
                      name: nameController.text,
                      description: descController.text,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      category: selectedCategory,
                      isAvailable: product?.isAvailable ?? true,
                      imageUrl: base64Image,
                    );
                    
                    if (product == null) {
                      ref.read(adminActionsProvider).addProduct(newProduct);
                    } else {
                      ref.read(adminActionsProvider).updateProduct(newProduct);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                  child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

// Helpers at the end of the file

ImagePicker _getPicker() => ImagePicker();
ImageSource _getImageSource() => ImageSource.gallery;
String _base64Encode(List<int> bytes) => base64Encode(bytes);
Uint8List _decodeBase64(String str) {
  final base64Str = str.split(',').last;
  return base64Decode(base64Str);
}
