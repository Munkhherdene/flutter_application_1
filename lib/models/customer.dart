// Customer Model
class Customer {
  final int id;
  final String name;
  final String phone;
  final String company;
  final String email;
  final String address;
  final int nuts;
  final Map<String, int> goods;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.company,
    required this.email,
    required this.address,
    this.nuts = 0,
    this.goods = const {},
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseGoods(dynamic goodsData) {
      if (goodsData is Map) {
        return goodsData.map((key, value) => MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0));
      }
      return {};
    }

    return Customer(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      phone: (json['mobile'] ?? '').toString(),
      company: (json['customergroupid'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      nuts: int.tryParse((json['nuts'] ?? '').toString()) ?? 0,
      goods: parseGoods(json['goods']),
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
      'nuts': nuts,
      'goods': goods,
    };
  }
}