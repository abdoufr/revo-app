import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import 'package:uuid/uuid.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

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
    // Check if item with exact same title and subtitle exists
    final existingIndex = state.indexWhere(
      (item) => item.title == title && item.subtitle == subtitle && item.isComposition == isComposition,
    );

    if (existingIndex >= 0) {
      // Increment quantity
      final existingItem = state[existingIndex];
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + 1);
      final newState = [...state];
      newState[existingIndex] = updatedItem;
      state = newState;
    } else {
      // Add new item
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
      state = [...state, newItem];
    }
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
      } else {
        // Remove item if quantity becomes 0
        removeItem(id);
      }
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCart() {
    state = [];
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
