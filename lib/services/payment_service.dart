import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> payFare({
    required String cardUid,
    required double amount,
    required String requestId
  }) async {
    final token = AuthService.accessToken;

    if (token == null) {
      throw Exception('Please log in first.');
    }

    final url = Uri.parse(
      '${AuthService.baseUrl}/payments',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'card_uid': cardUid,
        'amount': amount.toStringAsFixed(2),
        'request_id': requestId,
      }),
    );

    final Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      throw Exception('Invalid response from payment server.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    final detail = data['detail'];

    throw Exception(
      detail is String
          ? detail
          : 'Payment failed. Please try again.',
    );
  }
}
