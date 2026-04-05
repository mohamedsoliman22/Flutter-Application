class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'] as double,
      imageUrl: map['image_url'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Product) return false;
    
    Product otherProduct = other;
    if (id != null && otherProduct.id != null) {
      return id == otherProduct.id;
    }
    return name == otherProduct.name;
  }

  @override
  int get hashCode => id?.hashCode ?? name.hashCode;
}