class CartItem {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final int quantity;
  final String? imageUrl;
  final bool isComposition;
  final String? compositionCategoryKey;
  final List<String>? compositionIngredientIds;

  CartItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.isComposition = false,
    this.compositionCategoryKey,
    this.compositionIngredientIds,
  });

  CartItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? price,
    int? quantity,
    String? imageUrl,
    bool? isComposition,
    String? compositionCategoryKey,
    List<String>? compositionIngredientIds,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isComposition: isComposition ?? this.isComposition,
      compositionCategoryKey: compositionCategoryKey ?? this.compositionCategoryKey,
      compositionIngredientIds: compositionIngredientIds ?? this.compositionIngredientIds,
    );
  }

  // To allow easy conversion for Firestore/storage later
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'isComposition': isComposition,
      'compositionCategoryKey': compositionCategoryKey,
      'compositionIngredientIds': compositionIngredientIds,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
      imageUrl: map['imageUrl'],
      isComposition: map['isComposition'] ?? false,
      compositionCategoryKey: map['compositionCategoryKey'],
      compositionIngredientIds: map['compositionIngredientIds'] != null
          ? List<String>.from(map['compositionIngredientIds'])
          : null,
    );
  }
}
