import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/composer_provider.dart';
import '../../widgets/smart_image.dart';
import '../../services/storage_service.dart';

class AdminIngredientsScreen extends ConsumerWidget {
  const AdminIngredientsScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'pizza', 'label': 'Pizza', 'icon': '🍕'},
    {'key': 'tacos', 'label': 'Tacos', 'icon': '🌮'},
    {'key': 'sandwich', 'label': 'Sandwich', 'icon': '🥪'},
    {'key': 'cheese', 'label': 'Cheese', 'icon': '🍔'},
  ];

  void _showEditBasePricesDialog(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.read(composerCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [
      {'key': 'pizza', 'label': 'Pizza', 'icon': '🍕', 'color': 0xFFE53935, 'basePrice': 400.0},
      {'key': 'tacos', 'label': 'Tacos', 'icon': '🌮', 'color': 0xFFF57C00, 'basePrice': 450.0},
      {'key': 'sandwich', 'label': 'Sandwich', 'icon': '🥪', 'color': 0xFF388E3C, 'basePrice': 300.0},
      {'key': 'cheese', 'label': 'Assiette', 'icon': '🧀', 'color': 0xFFF9A825, 'basePrice': 600.0},
    ];

    // Local copy for editing
    List<Map<String, dynamic>> editedCategories = List.from(categories.map((c) => Map<String, dynamic>.from(c)));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Prix de Base (Composer)', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: editedCategories.map((cat) {
                  final index = editedCategories.indexOf(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(cat['icon'] as String, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(cat['label'] as String, style: Theme.of(context).textTheme.bodyLarge)),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            initialValue: (cat['basePrice'] as num).toDouble().toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(suffixText: 'DA', isDense: true),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) {
                                editedCategories[index]['basePrice'] = parsed;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(composerActionsProvider).saveCategories(editedCategories);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Prix de base mis à jour !')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

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
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        border: Border.all(color: Theme.of(context).primaryColor),
                      ),
                      child: base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: SmartImage(base64Image!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor, size: 30),
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
                        selectedColor: Theme.of(context).primaryColor,
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
                onPressed: () async {
                  final parsedPrice = double.tryParse(priceController.text.trim());
                  if (nameController.text.isNotEmpty && parsedPrice != null && parsedPrice >= 0 && selectedCategories.isNotEmpty) {
                    final price = parsedPrice;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator()),
                    );
                    try {
                      String? finalUrl = base64Image;
                      if (base64Image != null && base64Image!.startsWith('data:image')) {
                        finalUrl = await StorageService.uploadBase64Image(base64Image!, 'ingredients');
                      }
                      
                      final ingredient = Ingredient(
                        id: '',
                        name: nameController.text.trim(),
                        price: price,
                        categories: selectedCategories,
                        isAvailable: true,
                        imageUrl: finalUrl,
                      );
                      await ref.read(ingredientActionsProvider).addIngredient(ingredient);
                      
                      if (context.mounted) {
                        Navigator.pop(context); // close loader
                        Navigator.pop(context); // close dialog
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // close loader
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Remplissez tous les champs et choisissez au moins une catégorie.'), backgroundColor: AppTheme.error),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditIngredientDialog(BuildContext context, WidgetRef ref, Ingredient item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    List<String> selectedCategories = List.from(item.categories);
    String? base64Image = item.imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Modifier Ingrédient',
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
                        final f = await picker.pickImage(source: ImageSource.gallery, maxWidth: 250, imageQuality: 20);
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
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        border: Border.all(color: Theme.of(context).primaryColor),
                      ),
                      child: base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: SmartImage(base64Image!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor, size: 30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix de base (DA) (0 = Inclus)', isDense: true, suffixText: 'DA'),
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
                        selectedColor: Theme.of(context).primaryColor,
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
                onPressed: () async {
                  final parsedPrice = double.tryParse(priceController.text.trim());
                  if (nameController.text.isNotEmpty && parsedPrice != null && parsedPrice >= 0 && selectedCategories.isNotEmpty) {
                    final price = parsedPrice;
                    try {
                      String? finalUrl = base64Image;
                      if (base64Image != null && base64Image!.startsWith('data:image')) {
                        finalUrl = await StorageService.uploadBase64Image(base64Image!, 'ingredients');
                      }
                      final updated = Ingredient(
                        id: item.id,
                        name: nameController.text.trim(),
                        price: price,
                        categories: selectedCategories,
                        isAvailable: item.isAvailable,
                        imageUrl: finalUrl,
                      );
                      await ref.read(ingredientActionsProvider).updateIngredient(updated);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error));
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Remplissez tous les champs.'), backgroundColor: AppTheme.error),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
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
    ref.watch(composerCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ingrédients & Catégories', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          IconButton(
            icon: Icon(Icons.price_change_rounded, color: Theme.of(context).primaryColor),
            tooltip: 'Prix de Base',
            onPressed: () => _showEditBasePricesDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientDialog(context, ref),
        backgroundColor: Theme.of(context).primaryColor,
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
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.startsWith('data:image')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: SmartImage(item.imageUrl!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.egg_alt_rounded, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(item.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${item.price.toStringAsFixed(0)} DA', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: item.categories.map((cat) {
                            final catData = _categories.firstWhere((c) => c['key'] == cat, orElse: () => {'icon': '?', 'label': cat});
                            return Chip(
                              label: Text('${catData['icon']} ${catData['label']}', style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) => ref.read(ingredientActionsProvider).toggleAvailability(item.id, val),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                          onPressed: () => _showEditIngredientDialog(context, ref, item),
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
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}