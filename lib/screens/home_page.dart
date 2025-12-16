import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  bool isLoading = true;
  String? errorMessage;
  int userNuts = 100; // Default user nuts
  String userRole = 'distributor'; // Default role
  List<Product> products = [];
  Map<String, int> userGoods = {}; // Will be populated from products

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    fetchProducts();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedCustomers = await ApiService.fetchCustomers();
      setState(() {
        customers = fetchedCustomers;
        filteredCustomers = fetchedCustomers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Харилцагчийн мэдээлэл ачаалахад алдаа гарлаа: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchProducts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('keg_list')
          .get();
      final fetchedProducts = snapshot.docs
          .map((doc) => Product.fromJson(doc.data()..['id'] = doc.id))
          .toList();
      setState(() {
        products = fetchedProducts;
        userGoods = {for (var p in products) p.name: p.quantity};
      });
    } catch (e) {
      // Handle error, maybe show snackbar
      print('Error fetching products: $e');
    }
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredCustomers = customers;
      } else {
        filteredCustomers = customers.where((customer) {
          final name = customer.name.toLowerCase();
          final company = customer.company.toLowerCase();
          final phone = customer.phone.toLowerCase();
          final email = customer.email.toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
                 company.contains(searchLower) ||
                 phone.contains(searchLower) ||
                 email.contains(searchLower);
        }).toList();
      }
    });
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _addProduct() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Бараа бүртгэх'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Барааны нэр'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Тоо хэмжээ'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Үнэ (заавал биш)'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Тайлбар (заавал биш)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Цуцлах'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text);
              final description = descriptionController.text.trim();

              if (name.isEmpty || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Нэр болон тоо хэмжээ заавал оруулна уу')),
                );
                return;
              }

              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('keg_list')
                    .add({
                  'name': name,
                  'quantity': quantity,
                  'price': price,
                  'description': description.isEmpty ? null : description,
                });

                Navigator.pop(context);
                await fetchProducts(); // Refresh products
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Бараа амжилттай бүртгэгдлээ')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Алдаа гарлаа: $e')),
                );
              }
            },
            child: const Text('Бүртгэх'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProductsInFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final product in products) {
      final newQuantity = userGoods[product.name] ?? 0;
      if (newQuantity != product.quantity) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('keg_list')
            .doc(product.id);
        batch.update(docRef, {'quantity': newQuantity});
      }
    }
    await batch.commit();
  }

  Future<void> _updateCustomerInFirestore(String customerId, Map<String, int> updatedGoods) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customers')
        .doc(customerId)
        .update({'goods': updatedGoods});
  }

  void _showGoodsExchangeDialog(Customer customer) {
    String? selectedTakeItem;
    String? selectedGiveItem;
    final takeQuantityController = TextEditingController();
    final giveQuantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${customer.name} - Бараа солилцох'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Таны бараа: ${userGoods.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'),
                Text('Харилцагчийн бараа: ${customer.goods.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'),
                const SizedBox(height: 16),
                const Text('Харилцагчаас авах:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedTakeItem,
                  hint: const Text('Бараа сонгох'),
                  items: customer.goods.keys.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text('$item (${customer.goods[item]})'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedTakeItem = value),
                ),
                if (selectedTakeItem != null)
                  TextField(
                    controller: takeQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$selectedTakeItem тоо хэмжээ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Харилцагчид өгөх:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedGiveItem,
                  hint: const Text('Бараа сонгох'),
                  items: userGoods.keys.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text('$item (${userGoods[item]})'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedGiveItem = value),
                ),
                if (selectedGiveItem != null)
                  TextField(
                    controller: giveQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$selectedGiveItem тоо хэмжээ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Цуцлах'),
            ),
            ElevatedButton(
              onPressed: () async {
                final takeQuantity = int.tryParse(takeQuantityController.text) ?? 0;
                final giveQuantity = int.tryParse(giveQuantityController.text) ?? 0;

                if (selectedTakeItem != null && takeQuantity > (customer.goods[selectedTakeItem] ?? 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Харилцагчид хангалттай бараа байхгүй байна')),
                  );
                  return;
                }

                if (selectedGiveItem != null && giveQuantity > (userGoods[selectedGiveItem] ?? 0)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Танд хангалттай бараа байхгүй байна')),
                  );
                  return;
                }

                Map<String, int> updatedGoods = Map<String, int>.from(customer.goods);

                setState(() {
                  if (selectedTakeItem != null) {
                    userGoods[selectedTakeItem!] = (userGoods[selectedTakeItem!] ?? 0) + takeQuantity;
                    updatedGoods[selectedTakeItem!] = (updatedGoods[selectedTakeItem!] ?? 0) - takeQuantity;
                  }
                  if (selectedGiveItem != null) {
                    userGoods[selectedGiveItem!] = (userGoods[selectedGiveItem!] ?? 0) - giveQuantity;
                    updatedGoods[selectedGiveItem!] = (updatedGoods[selectedGiveItem!] ?? 0) + giveQuantity;
                  }
                  // Update customer in the list
                  final index = customers.indexWhere((c) => c.id == customer.id);
                  if (index != -1) {
                    customers[index] = Customer(
                      id: customer.id,
                      name: customer.name,
                      phone: customer.phone,
                      company: customer.company,
                      email: customer.email,
                      address: customer.address,
                      nuts: customer.nuts,
                      goods: updatedGoods,
                    );
                    filteredCustomers = customers.where((c) {
                      final name = c.name.toLowerCase();
                      final company = c.company.toLowerCase();
                      final phone = c.phone.toLowerCase();
                      final email = c.email.toLowerCase();
                      final searchLower = searchQuery.toLowerCase();

                      return name.contains(searchLower) ||
                             company.contains(searchLower) ||
                             phone.contains(searchLower) ||
                             email.contains(searchLower);
                    }).toList();
                  }
                });

                await _updateProductsInFirestore();
                await _updateCustomerInFirestore(customer.id.toString(), updatedGoods);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Бараа солилцлоо: авсан ${selectedTakeItem ?? ''} $takeQuantity, өгсөн ${selectedGiveItem ?? ''} $giveQuantity')),
                );
              },
              child: const Text('Батлах'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Харилцагч хайх'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
            tooltip: 'Гарах',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: updateSearch,
              decoration: InputDecoration(
                hintText: 'Харилцагчын нэр, компани эсвэл утасны дугаар...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          updateSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Нийт ${filteredCustomers.length} харилцагч',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '("$searchQuery" хайлтаар)',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Customer list or loading/error states
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Харилцагчийн мэдээлэл ачааллаж байна...'),
                      ],
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Алдаа гарлаа',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchCustomers,
                              child: const Text('Дахин оролдох'),
                            ),
                          ],
                        ),
                      )
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'Харилцагч байхгүй байна'
                                      : 'Хайлтын үр дүн олдсонгүй',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'API-с мэдээлэл ачаалах боломжгүй байна'
                                      : 'Өөр түлхүүр үгээр хайна уу',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              return GestureDetector(
                                onDoubleTap: userRole == 'distributor' ? () => _showGoodsExchangeDialog(customer) : null,
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueAccent,
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                customer.company,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              customer.phone,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                customer.email,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.inventory, size: 16, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Бараа: ${customer.goods.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(customer.name),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Компани: ${customer.company}'),
                                                Text('Утас: ${customer.phone}'),
                                                Text('Email: ${customer.email}'),
                                                Text('Хаяг: ${customer.address}'),
                                                Text('Торх: ${customer.nuts}'),                                              Text('Бараа: ${customer.goods.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'),                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Хаах'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Дэлгэрэнгүй',
                                    ),
                                    onTap: () {
                                      // Could navigate to customer detail page
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${customer.name} сонгогдлоо')),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: Colors.blueAccent,
        tooltip: 'Бараа бүртгэх',
        child: const Icon(Icons.add),
      ),
    );
  }
}