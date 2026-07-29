import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import 'package:uuid/uuid.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  static const _cartKey = 'saved_cart_items';

  @override
  List<CartItem> build() {
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cartKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final loadedItems = decoded
            .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
            .toList();
        state = loadedItems;
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(items.map((i) => i.toMap()).toList());
      await prefs.setString(_cartKey, jsonStr);
    } catch (_) {}
  }

  final _uuid = const Uuid();

  void addItem({
    required String title,
    required String subtitle,
    required double price,
    String? imageUrl,
    bool isComposition = false,
    String? compositionCategoryKey,
    List<String>? compositionIngredientIds,
  }) {
    final existingIndex = state.indexWhere(
      (item) => item.title == title && item.subtitle == subtitle && item.isComposition == isComposition,
    );

    List<CartItem> newState;
    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
      newState = [...state];
      newState[existingIndex] = updatedItem;
    } else {
      final newItem = CartItem(
        id: _uuid.v4(),
        title: title,
        subtitle: subtitle,
        price: price,
        quantity: 1,
        imageUrl: imageUrl,
        isComposition: isComposition,
        compositionCategoryKey: compositionCategoryKey,
        compositionIngredientIds: compositionIngredientIds,
      );
      newState = [...state, newItem];
    }
    state = newState;
    _saveToPrefs(newState);
  }

  void updateItem({
    required String id,
    required String title,
    required String subtitle,
    required double price,
    String? imageUrl,
    bool isComposition = false,
    String? compositionCategoryKey,
    List<String>? compositionIngredientIds,
  }) {
    final index = state.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final existingItem = state[index];
      final updatedItem = existingItem.copyWith(
        title: title,
        subtitle: subtitle,
        price: price,
        imageUrl: imageUrl,
        isComposition: isComposition,
        compositionCategoryKey: compositionCategoryKey,
        compositionIngredientIds: compositionIngredientIds,
      );
      final newState = [...state];
      newState[index] = updatedItem;
      state = newState;
      _saveToPrefs(newState);
    }
  }

  void incrementQuantity(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final item = state[index];
      final updatedItem = item.copyWith(quantity: item.quantity + 1);
      final newState = [...state];
      newState[index] = updatedItem;
      state = newState;
      _saveToPrefs(newState);
    }
  }

  void decrementQuantity(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final item = state[index];
      if (item.quantity > 1) {
        final updatedItem = item.copyWith(quantity: item.quantity - 1);
        final newState = [...state];
        newState[index] = updatedItem;
        state = newState;
        _saveToPrefs(newState);
      } else {
        removeItem(id);
      }
    }
  }

  void removeItem(String id) {
    final newState = state.where((item) => item.id != id).toList();
    state = newState;
    _saveToPrefs(newState);
  }

  void clearCart() {
    state = [];
    _saveToPrefs([]);
  }

  double get totalPrice {
    return state.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  int get totalItems {
    return state.fold(0, (total, item) => total + item.quantity);
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});
