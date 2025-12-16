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
    final token = await getToken();

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _logger.info('Response body: ${response.body}');
      try {
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
        _logger.info('Customers loaded: ${jsonData.length}');
        final customers = jsonData.map((e) {
          try {
            return Customer.fromJson(e as Map<String, dynamic>);
          } catch (e) {
            _logger.severe('Error parsing customer: $e, data: $e');
            throw Exception('Failed to parse customer data');
          }
        }).toList();
        return customers;
      } catch (e) {
        _logger.severe('Error decoding JSON: $e, body: ${response.body}');
        throw Exception('Failed to decode customer data');
      }
    } else {
      _logger.severe(
        'Customer API error ${response.statusCode}: ${response.body}',
      );
      throw Exception('Failed to load customers: ${response.statusCode}');
    }
  }
}