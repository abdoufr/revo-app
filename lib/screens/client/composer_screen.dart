import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  String? _selectedCategory;
  final Set<String> _selectedIngredientIds = {};
  double _totalPrice = 0.0;
  List<Ingredient> _allIngredients = [];

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'pizza', 'label': 'Pizza', 'icon': '🍕', 'color': 0xFFE53935},
    {'key': 'tacos', 'label': 'Tacos', 'icon': '🌮', 'color': 0xFFF57C00},
    {'key': 'sandwich', 'label': 'Sandwich', 'icon': '🥪', 'color': 0xFF388E3C},
    {'key': 'cheese', 'label': 'Cheese', 'icon': '🧀', 'color': 0xFFF9A825},
  ];

  void _toggleIngredient(Ingredient ingredient) {
    setState(() {
      if (_selectedIngredientIds.contains(ingredient.id)) {
        _selectedIngredientIds.remove(ingredient.id);
        _totalPrice -= ingredient.price;
      } else {
        _selectedIngredientIds.add(ingredient.id);
        _totalPrice += ingredient.price;
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedCategory = null;
      _selectedIngredientIds.clear();
      _totalPrice = 0.0;
    });
  }

  void _showSummary() {
    final selectedIngredients = _allIngredients.where((i) => _selectedIngredientIds.contains(i.id)).toList();
    final catData = _categories.firstWhere((c) => c['key'] == _selectedCategory);

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const Divider(height: 24),
            ...selectedIngredients.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${i.name}', style: Theme.of(context).textTheme.bodyLarge),
                      Text('${i.price.toStringAsFixed(0)} DA',
                          style: const TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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
              Navigator.pop(ctx);
              _reset();
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Nouvelle composition', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Composer mon Plat 🍕',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          if (_selectedCategory != null)
            TextButton(
              onPressed: _reset,
              child: const Text('Recommencer', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
        ],
      ),
      body: _selectedCategory == null ? _buildCategoryPicker() : _buildIngredientPicker(),
      bottomNavigationBar: _selectedCategory != null && _selectedIngredientIds.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildCategoryPicker() {
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
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _categories.map((cat) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['key'] as String),
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
  }

  Widget _buildIngredientPicker() {
    final ingredientsAsync = ref.watch(ingredientsByCategoryProvider(_selectedCategory!));
    final catData = _categories.firstWhere((c) => c['key'] == _selectedCategory);
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
                          const SizedBox(width: 16),
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
      loading: () => const Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
    );
  }

  Widget _buildBottomBar() {
    final catData = _categories.firstWhere((c) => c['key'] == _selectedCategory);
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
