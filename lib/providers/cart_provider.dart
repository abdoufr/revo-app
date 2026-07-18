import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import 'package:uuid/uuid.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  final _uuid = const Uuid();

  void addItem({
    required String title,
    required String subtitle,
    required double price,
    String? imageUrl,
  }) {
    // Check if item with exact same title and subtitle exists
    final existingIndex = state.indexWhere(
      (item) => item.title == title && item.subtitle == subtitle,
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
      );
      state = [...state, newItem];
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

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
