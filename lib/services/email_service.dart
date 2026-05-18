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

  static Future<bool> sendResetEmail({
    required String toEmail,
    required String toName,
    required String code,
  }) async {
    try {
      final html = _buildResetHtml(toName.isNotEmpty ? toName : 'there', code);
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': toEmail,
          'toName': toName,
          'subject': 'Reset your ChaseIt password',
          'code': code,
          'type': 'reset',
        }),
      );
      print('[EmailService] Reset Status: \${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[EmailService] Reset Error: \$e');
      return false;
    }
  }

  static String _buildResetHtml(String name, String code) => '''
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f7f4ef;font-family:sans-serif">
<table width="100%" cellpadding="0" cellspacing="0">
<tr><td align="center" style="padding:40px 20px">
<table width="480" cellpadding="0" cellspacing="0"
  style="background:#ffffff;border-radius:16px;overflow:hidden">
  <tr><td style="background:#1a1612;padding:24px 32px">
    <span style="color:#ffffff;font-size:20px;font-weight:800">⏱ ChaseIt</span>
  </td></tr>
  <tr><td style="padding:36px 32px">
    <h1 style="margin:0 0 8px;font-size:24px;font-weight:800;color:#1a1612">Reset your password</h1>
    <p style="margin:0 0 24px;font-size:15px;color:#8a8070;line-height:1.6">
      Hi \$name, use this code to reset your ChaseIt password.
    </p>
    <div style="background:#f7f4ef;border-radius:12px;padding:28px;text-align:center;margin:0 0 24px">
      <div style="font-size:48px;font-weight:800;letter-spacing:16px;color:#e84c1e;font-family:monospace">\$code</div>
      <p style="margin:10px 0 0;font-size:12px;color:#8a8070">Expires in 10 minutes</p>
    </div>
    <p style="margin:0;font-size:13px;color:#c4bdb0">If you did not request a reset, ignore this email.</p>
  </td></tr>
  <tr><td style="background:#f7f4ef;padding:20px 32px;border-top:1px solid #f0ece5">
    <p style="margin:0;font-size:12px;color:#c4bdb0;text-align:center">© 2026 ChaseIt</p>
  </td></tr>
</table></td></tr></table></body></html>''';
}