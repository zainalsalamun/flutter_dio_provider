class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int stock;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No Description',
      // Handle various number types safely
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
    };
  }
}
