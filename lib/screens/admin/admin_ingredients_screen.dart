import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';

class AdminIngredientsScreen extends ConsumerWidget {
  const AdminIngredientsScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'pizza', 'label': 'Pizza', 'icon': '🍕'},
    {'key': 'tacos', 'label': 'Tacos', 'icon': '🌮'},
    {'key': 'sandwich', 'label': 'Sandwich', 'icon': '🥪'},
    {'key': 'cheese', 'label': 'Cheese', 'icon': '🧀'},
  ];

  void _showAddIngredientDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    List<String> selectedCategories = [];
    String? base64Image;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Nouvel Ingrédient',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, imageQuality: 80);
                        if (f != null) {
                          final bytes = await f.readAsBytes();
                          setState(() => base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}');
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        border: Border.all(color: AppTheme.primaryOrange),
                      ),
                      child: base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.memory(base64Decode(base64Image!.split(',').last), fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryOrange, size: 30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom (ex: Mozzarella)', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix (DA)', isDense: true, suffixText: 'DA'),
                  ),
                  const SizedBox(height: 16),
                  Text('Disponible dans :', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = selectedCategories.contains(cat['key']);
                      return FilterChip(
                        label: Text('${cat['icon']} ${cat['label']}'),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryOrange,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selectedCategories.add(cat['key'] as String);
                            } else {
                              selectedCategories.remove(cat['key']);
                            }
                          });
                        },
                      );
                    }).toList(),
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
                  final price = double.tryParse(priceController.text.trim()) ?? 0;
                  if (nameController.text.isNotEmpty && price > 0 && selectedCategories.isNotEmpty) {
                    final ingredient = Ingredient(
                      id: '',
                      name: nameController.text.trim(),
                      price: price,
                      categories: selectedCategories,
                      isAvailable: true,
                      imageUrl: base64Image,
                    );
                    ref.read(ingredientActionsProvider).addIngredient(ingredient);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Remplissez tous les champs et choisissez au moins une catégorie.'), backgroundColor: AppTheme.error),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ingrédients & Catégories', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientDialog(context, ref),
        backgroundColor: AppTheme.primaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ingredientsAsync.when(
        data: (ingredients) {
          if (ingredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🥦', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Aucun ingrédient ajouté.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final item = ingredients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.startsWith('data:image')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.memory(base64Decode(item.imageUrl!.split(',').last), fit: BoxFit.cover),
                            )
                          : const Icon(Icons.egg_alt_rounded, color: AppTheme.primaryOrange),
                    ),
                    title: Text(item.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${item.price.toStringAsFixed(0)} DA', style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: item.categories.map((cat) {
                            final catData = _categories.firstWhere((c) => c['key'] == cat, orElse: () => {'icon': '?', 'label': cat});
                            return Chip(
                              label: Text('${catData['icon']} ${catData['label']}', style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.isAvailable,
                          activeColor: AppTheme.primaryOrange,
                          onChanged: (val) => ref.read(ingredientActionsProvider).toggleAvailability(item.id, val),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () => ref.read(ingredientActionsProvider).deleteIngredient(item.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
