import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/product.dart';
import '../../l10n/app_translations.dart';
import '../../widgets/smart_image.dart';
import '../../services/storage_service.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              try {
                final snapshot = await FirebaseFirestore.instance.collection('products').limit(1).get();
                final doc = snapshot.docs.first;
                final data = doc.data();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Text('ID: ${doc.id}\nKeys: ${data.keys.join(', ')}\nGallery isList: ${data['gallery'] is List}\nGallery length: ${data['gallery']?.length ?? 0}'),
                  ),
                );
              } catch (e) {
                print(e);
              }
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddProductDialog(context, ref, availableCategories);
        },
        backgroundColor: Theme.of(context).primaryColor,
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
                    subtitle: Text('${product.price} DA', style: TextStyle(color: Theme.of(context).primaryColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: product.isAvailable,
                          activeColor: Theme.of(context).primaryColor,
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
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (error, stack) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, List<String> categories, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final ingredientsController = TextEditingController(text: product?.ingredients.join(', ') ?? '');
    
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
    List<String> galleryImages = product?.gallery.toList() ?? [];

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
                          final pickedFile = await picker.pickImage(source: _getImageSource(), maxWidth: 500, imageQuality: 60);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            // We import dart:convert at the top of file
                            final base64String = 'data:image/jpeg;base64,' + _base64Encode(bytes);
                            
                            // Check size
                            final sizeInMB = base64String.length / (1024 * 1024);
                            if (sizeInMB > 0.5) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Image principale trop lourde (${sizeInMB.toStringAsFixed(2)} Mo) ! La base de données risque de refuser.'), backgroundColor: Colors.orange));
                              }
                            }

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
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).primaryColor, width: 1, style: BorderStyle.solid),
                        ),
                        child: base64Image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SmartImage(base64Image!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor, size: 40),
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: ingredientsController,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Ingrédients (séparés par des virgules)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Images de la description (Galerie)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...galleryImages.asMap().entries.map((entry) {
                            int idx = entry.key;
                            String imgBase64 = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                                image: DecorationImage(
                                  image: SmartImage.getProvider(imgBase64),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      galleryImages.removeAt(idx);
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () async {
                              try {
                                final picker = _getPicker();
                                final pickedFile = await picker.pickImage(source: _getImageSource(), maxWidth: 400, imageQuality: 40);
                                if (pickedFile != null) {
                                  final bytes = await pickedFile.readAsBytes();
                                  final base64String = 'data:image/jpeg;base64,' + _base64Encode(bytes);
                                  setState(() {
                                    galleryImages.add(base64String);
                                  });
                                }
                              } catch (e) {}
                            },
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).primaryColor, style: BorderStyle.solid),
                              ),
                              child: Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ],
                      ),
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
                  onPressed: () async {
                    try {
                      // Upload main image if it's base64
                      String? finalImageUrl = base64Image;
                      if (base64Image != null && base64Image!.startsWith('data:image')) {
                        finalImageUrl = await StorageService.uploadBase64Image(base64Image!, 'products');
                      }

                      // Upload gallery images
                      List<String> finalGallery = [];
                      for (var img in galleryImages) {
                        if (img.startsWith('data:image')) {
                          final url = await StorageService.uploadBase64Image(img, 'products_gallery');
                          finalGallery.add(url);
                        } else {
                          finalGallery.add(img);
                        }
                      }

                      final newProduct = Product(
                        id: product?.id ?? '',
                        name: nameController.text,
                        description: descController.text,
                        price: double.tryParse(priceController.text) ?? 0.0,
                        category: selectedCategory,
                        isAvailable: product?.isAvailable ?? true,
                        imageUrl: finalImageUrl,
                        ingredients: ingredientsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        gallery: finalGallery,
                      );
                      
                      if (product == null) {
                        await ref.read(adminActionsProvider).addProduct(newProduct);
                      } else {
                        await ref.read(adminActionsProvider).updateProduct(newProduct);
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Close product dialog
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit enregistré avec succès !'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close product dialog
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
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