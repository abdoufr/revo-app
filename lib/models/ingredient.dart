class Ingredient {
  final String id;
  final String name;
  final double price;
  final List<String> categories; // ['pizza', 'tacos', 'sandwich', 'cheese']
  final bool isAvailable;
  final String? imageUrl;

  Ingredient({
    required this.id,
    required this.name,
    required this.price,
    required this.categories,
    required this.isAvailable,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'categories': categories,
      'is_available': isAvailable,
      'image_url': imageUrl ?? '',
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map, String id) {
    return Ingredient(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      categories: List<String>.from(map['categories'] ?? []),
      isAvailable: map['is_available'] ?? true,
      imageUrl: map['image_url'],
    );
  }
}
