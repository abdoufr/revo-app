class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;
  final String? imageUrl; // Base64 or URL
  final List<String> ingredients;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.imageUrl,
    this.ingredients = const [],
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      isAvailable: data['is_available'] ?? true,
      imageUrl: data['imageUrl'],
      ingredients: data['ingredients'] != null ? List<String>.from(data['ingredients']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'is_available': isAvailable,
      'ingredients': ingredients,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
