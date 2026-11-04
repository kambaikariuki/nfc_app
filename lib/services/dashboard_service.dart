import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DashboardService {
  static Future<dynamic> _get(String endpoint) async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Request failed (${response.statusCode}): ${response.body}',
    );
  }

  // Passenger
  static Future<Map<String, dynamic>> getPassengerBalance() async {
    return await _get('/passengers/balance')
        as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPassengerTransactions() async {
    return await _get('/passengers/transactions')
        as List<dynamic>;
  }

  // Operator
  static Future<Map<String, dynamic>> getOperatorWallet() async {
    return await _get('/operators/wallet')
        as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getOperatorTransactions() async {
    return await _get('/operators/transactions')
        as List<dynamic>;
  }
}