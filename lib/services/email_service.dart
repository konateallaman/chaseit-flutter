import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resend API — free tier: 3,000 emails/month
/// Sign up at resend.com, get your API key, add to your Vercel env vars
class EmailService {
  // Your Vercel proxy endpoint (keeps API key server-side)
  static const String _baseUrl = 'https://konateallaman-chaseit-flutter-oogu.vercel.app';

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
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
