// Product Model
class Product {
  final String id;
  final String name;
  final int quantity;
  final double? price; // Optional price
  final String? description; // Optional description

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    this.price,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description,
    };
  }
}