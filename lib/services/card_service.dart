
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class CardService {
  // Link a new NFC card.
  static Future<Map<String, dynamic>> linkCard({
    required String uid,
  }) async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/cards/register'),
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

  // Retrieve the passenger's cards.
  static Future<List<dynamic>> getCards() async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/cards/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<dynamic>.from(data);
    }

    throw Exception(
      data['detail'] ?? 'Unable to retrieve NFC cards.',
    );
  }

  // Deactivate the passenger's active card.
  static Future<Map<String, dynamic>> deactivateCard() async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/cards/delete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['detail'] ?? 'Unable to deactivate NFC card.',
    );
  }
}
