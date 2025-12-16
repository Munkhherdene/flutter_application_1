import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/customer.dart';

class ApiService {
  static final Logger _logger = Logger('ApiService');
  static String? _cachedToken;
  static DateTime? _tokenExpiry;

  // ================= TOKEN API =================
  static const String _tokenUrl =
      'https://distapiv1.smartlogic.mn/oauth/token';

  static Future<String> getToken() async {
    // Check if token is cached and not expired (assuming 1 hour expiry for example)
    if (_cachedToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': 'ccdist',
        'password': 'YjYHO3nM2q10sa4i7E43',
        'grant_type': 'password',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final expiresIn = data['expires_in'] ?? 3600; // Default to 1 hour if not provided

      if (token == null) {
        throw Exception('Token is null');
      }

      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      _logger.info('Token received and cached');
      return token;
    } else {
      _logger.severe(
        'Token error ${response.statusCode}: ${response.body}',
      );
      throw Exception('Failed to get token');
    }
  }

  // ================= CUSTOMER API =================
  static const String _baseUrl =
      'https://distapiv1.smartlogic.mn/api/info/customers';

  static Future<List<Customer>> fetchCustomers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('customers')
        .get();

    if (snapshot.docs.isEmpty) {
      // Import from API if no customers in Firebase
      await _importCustomersFromApi(userId);
      // Fetch again
      final newSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customers')
          .get();
      final customers = newSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Customer.fromJson(data);
      }).toList();
      _logger.info('Customers imported and loaded from Firebase: ${customers.length}');
      return customers;
    }

    final customers = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Customer.fromJson(data);
    }).toList();

    _logger.info('Customers loaded from Firebase: ${customers.length}');
    return customers;
  }

  static Future<void> _importCustomersFromApi(String userId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> jsonData;
      if (decoded is List) {
        jsonData = decoded;
      } else if (decoded is Map && decoded.containsKey('customers')) {
        jsonData = decoded['customers'] as List<dynamic>;
      } else if (decoded is Map && decoded.containsKey('data')) {
        jsonData = decoded['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format');
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final item in jsonData) {
        final customer = Customer.fromJson(item as Map<String, dynamic>);
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('customers')
            .doc(customer.id.toString());
        batch.set(docRef, customer.toJson());
      }
      await batch.commit();
      _logger.info('Customers imported to Firebase: ${jsonData.length}');
    } else {
      throw Exception('Failed to import customers from API');
    }
  }
}