import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8000';

  // Available while the app is running.
  static String? accessToken;

    
  static Future<Map<String, dynamic>> login({
    required String role,
    required String email,
    required String password,
  }) async {
    final endpoint = role == 'Passenger'
        ? '/auth/passenger/login'
        : '/auth/operator/login';

    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The server returned an invalid response.');
    }

    if (response.statusCode == 200) {
      final token = data['access_token'];

      if (token is! String || token.isEmpty) {
        throw Exception('Login response did not contain an access token.');
      }

      accessToken = token;
      return data;
    }

    final detail = data['detail'];
    throw Exception(
      detail is String ? detail : 'Login failed (${response.statusCode}).',
    );
  }

  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      accessToken = null;
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Could not load user (${response.statusCode}): ${response.body}',
    );
  }

}
