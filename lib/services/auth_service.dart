import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';

  static String? accessToken;

  // Log in
  static Future<Map<String, dynamic>> login({
    required String role,
    required String email,
    required String password,
  }) async {
    final endpoint = role.toLowerCase() == 'passenger'
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', role.toLowerCase());

      return data;
    }

    final detail = data['detail'];

    throw Exception(
      detail is String ? detail : 'Login failed (${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> register({
    required String role,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final endpoint = role == 'Passenger'
        ? '/auth/passenger/register'
        : '/auth/operator/register';

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['detail'] ?? 'Registration failed.');
  }

  // Restore token when the app starts.
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
  }

  // Get current authenticated user.
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Could not load user (${response.statusCode}): ${response.body}',
    );
  }

  // Logout and clear saved session.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('access_token');
    await prefs.remove('user_role');

    accessToken = null;
  }
}
