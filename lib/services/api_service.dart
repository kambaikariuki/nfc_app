import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Change to deployed address on render https://nfc-app-p9pi.onrender.com

  static const String baseUrl = "http://localhost:8000";

  static Future<Map<String, dynamic>> testConnection() async {
    final response = await http
        .get(Uri.parse('$baseUrl/'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Backend returned status ${response.statusCode}');
  }
}
