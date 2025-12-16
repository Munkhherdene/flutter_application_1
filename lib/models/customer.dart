// Customer Model
class Customer {
  final int id;
  final String name;
  final String phone;
  final String company;
  final String email;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.company,
    required this.email,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      phone: (json['mobile'] ?? '').toString(),
      company: (json['customergroupid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'company': company,
      'email': email,
      'address': address,
    };
  }
}