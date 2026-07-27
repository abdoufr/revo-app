import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/composer_provider.dart';
import '../../providers/cart_provider.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  final String? editingCartItemId;
  final String? initialCategoryKey;
  final List<String>? initialIngredientIds;

  const ComposerScreen({
    super.key,
    this.editingCartItemId,
    this.initialCategoryKey,
    this.initialIngredientIds,
  });

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  String? _selectedCategory;
  final Set<String> _selectedIngredientIds = {};
  List<Ingredient> _allIngredients = [];
  List<Map<String, dynamic>> _currentCategories = [];

  double get _totalPrice {
    if (_selectedCategory == null || _currentCategories.isEmpty) return 0.0;
    try {
      final catData = _currentCategories.firstWhere((c) => c['key'] == _selectedCategory);
      double total = (catData['basePrice'] as num).toDouble();
      for (var id in _selectedIngredientIds) {
        final ing = _allIngredients.firstWhere((i) => i.id == id);
        total += ing.price;
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryKey != null) {
      _selectedCategory = widget.initialCategoryKey;
    }
    if (widget.initialIngredientIds != null) {
      _selectedIngredientIds.addAll(widget.initialIngredientIds!);
    }
  }

  void _toggleIngredient(Ingredient ingredient) {
    setState(() {
      if (_selectedIngredientIds.contains(ingredient.id)) {
        _selectedIngredientIds.remove(ingredient.id);
      } else {
        _selectedIngredientIds.add(ingredient.id);
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedCategory = null;
      _selectedIngredientIds.clear();
    });
  }

  Uint8List _decodeBase64Safe(String imageUrl) {
    try {
      final base64Str = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
      return base64Decode(base64Str);
    } catch (_) {
      return Uint8List(0);
    }
  }

  void _showSummary() {
    final selectedIngredients = _allIngredients.where((i) => _selectedIngredientIds.contains(i.id)).toList();
    final catData = _currentCategories.firstWhere((c) => c['key'] == _selectedCategory);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(catData['icon'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ma Composition',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(catData['label'] as String,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Base ${catData['label']}', style: Theme.of(context).textTheme.bodyLarge),
                Text('${(catData['basePrice'] as num).toDouble().toStringAsFixed(0)} DA',
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            ...selectedIngredients.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${i.name}', style: Theme.of(context).textTheme.bodyLarge),
                      Text('${i.price.toStringAsFixed(0)} DA',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '${_totalPrice.toStringAsFixed(0)} DA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Construct subtitle from ingredients
              final ingredientsList = selectedIngredients.map((i) => i.name).join(', ');
              
              if (widget.editingCartItemId != null) {
                ref.read(cartProvider.notifier).updateItem(
                  id: widget.editingCartItemId!,
                  title: 'Composition ${catData['label']}',
                  subtitle: ingredientsList.isNotEmpty ? ingredientsList : 'Base seule',
                  price: _totalPrice,
                  isComposition: true,
                  compositionCategoryKey: _selectedCategory,
                  compositionIngredientIds: _selectedIngredientIds.toList(),
                );
              } else {
                ref.read(cartProvider.notifier).addItem(
                  title: 'Composition ${catData['label']}',
                  subtitle: ingredientsList.isNotEmpty ? ingredientsList : 'Base seule',
                  price: _totalPrice,
                  isComposition: true,
                  compositionCategoryKey: _selectedCategory,
                  compositionIngredientIds: _selectedIngredientIds.toList(),
                );
              }
              
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close composer (if opened as modal/route)
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.editingCartItemId != null ? 'Composition mise à jour' : 'Composition ajoutée au panier'),
                  backgroundColor: AppTheme.success,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(widget.editingCartItemId != null ? Icons.save : Icons.shopping_cart_checkout, color: Colors.white),
            label: Text(widget.editingCartItemId != null ? 'Enregistrer' : 'Ajouter au panier', style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(composerCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Composer mon Plat 🍕',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          if (_selectedCategory != null)
            TextButton(
              onPressed: _reset,
              child: Text('Recommencer', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          _currentCategories = categories;
          return _selectedCategory == null ? _buildCategoryPicker(categories) : _buildIngredientPicker();
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
      bottomNavigationBar: _selectedCategory != null && _selectedIngredientIds.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildCategoryPicker(List<Map<String, dynamic>> categories) {
    return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Que voulez-vous composer ?',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.extent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: categories.map((cat) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['key'] as String;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(cat['color'] as int).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Color(cat['color'] as int), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat['icon'] as String, style: const TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(cat['color'] as int),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'À partir de ${(cat['basePrice'] as num).toDouble().toStringAsFixed(0)} DA',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
        );
  }

  Widget _buildIngredientPicker() {
    final ingredientsAsync = ref.watch(ingredientsByCategoryProvider(_selectedCategory!));
    final catData = _currentCategories.firstWhere((c) => c['key'] == _selectedCategory);
    final catColor = Color(catData['color'] as int);

    return ingredientsAsync.when(
      data: (ingredients) {
        _allIngredients = ingredients;

        if (ingredients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(catData['icon'] as String, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text("Aucun ingrédient disponible pour ${catData['label']}.",
                    style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: catColor.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Text(catData['icon'] as String, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    'Choisissez vos ingrédients',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  final isSelected = _selectedIngredientIds.contains(ingredient.id);

                  return GestureDetector(
                    onTap: () => _toggleIngredient(ingredient),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withOpacity(0.12) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? catColor : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? catColor : Colors.transparent,
                              border: Border.all(color: isSelected ? catColor : Colors.grey),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Photo de l'ingrédient
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: catColor.withOpacity(0.1),
                            ),
                            child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.memory(
                                      Uri.parse(ingredient.imageUrl!).data?.contentAsBytes() ??
                                          _decodeBase64Safe(ingredient.imageUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(Icons.fastfood_rounded, color: catColor, size: 22),
                                    ),
                                  )
                                : Icon(Icons.fastfood_rounded, color: catColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ingredient.name,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ),
                          Text(
                            '+ ${ingredient.price.toStringAsFixed(0)} DA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? catColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
    );
  }

  Widget _buildBottomBar() {
    final catData = _currentCategories.firstWhere((c) => c['key'] == _selectedCategory);
    final catColor = Color(catData['color'] as int);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total estimé', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${_totalPrice.toStringAsFixed(0)} DA',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: catColor),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed: _showSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: catColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Voir ma composition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}