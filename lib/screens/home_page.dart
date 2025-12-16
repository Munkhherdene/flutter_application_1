import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer.dart';
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

  @override
  void initState() {
    super.initState();
    fetchCustomers();
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
                    '("${searchQuery}" хайлтаар)',
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
                              return Card(
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
                                            ],
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
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Could add new customer functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Шинэ харилцагч нэмэх')),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
        tooltip: 'Шинэ харилцагч',
      ),
    );
  }
}