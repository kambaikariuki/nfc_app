import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Android emulator:
  static const String baseUrl =  "http://127.0.0.1:8000";

  // For a physical phone, replace the address above with your
  // computer's local network IP, e.g. http://192.168.1.10:8000

  static Future<Map<String, dynamic>> testConnection() async {
    final response = await http
        .get(Uri.parse('$baseUrl/'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Backend returned status ${response.statusCode}',
    );
  }
}