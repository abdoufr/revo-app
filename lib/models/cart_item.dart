class CartItem {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  CartItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
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
    );
  }
}
