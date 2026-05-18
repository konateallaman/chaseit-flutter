import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _baseUrl = 'https://chaseit-api.vercel.app';

  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String toName,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': toEmail,
          'toName': toName,
          'subject': 'Verify your ChaseIt account',
          'code': code,
          'type': 'verification',
        }),
      );
      print('[EmailService] Status: ${res.statusCode} Body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('[EmailService] Error: $e');
      return false;
    }
  }
}