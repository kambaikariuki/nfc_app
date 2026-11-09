import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class CardService {
  static Future<Map<String, dynamic>> linkCard({
    required String uid,
  }) async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.post(
      Uri.parse(
        '${AuthService.baseUrl}/passengers/me/cards',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail'] ?? 'Unable to link NFC card.',
    );
  }
}
