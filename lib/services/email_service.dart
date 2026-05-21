import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _baseUrl = 'https://chaseit-api.vercel.app';

  // ── VERIFICATION EMAIL ───────────────────────────────────
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
      print('[EmailService] Verification status: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      print('[EmailService] Error: $e');
      return false;
    }
  }

  // ── RESET PASSWORD EMAIL ─────────────────────────────────
  static Future<bool> sendResetEmail({
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
          'subject': 'Reset your ChaseIt password',
          'code': code,
          'type': 'reset',
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[EmailService] Reset error: $e');
      return false;
    }
  }

  // ── CHASE EMAIL ──────────────────────────────────────────
  static Future<bool> sendChaseEmail({
    required String toEmail,
    required String toName,
    required String message,
    required double amount,
    required String due,
    required String sender,
  }) async {
    try {
      final amountStr = amount.toStringAsFixed(2);
      final html = '<div style="font-family:sans-serif;max-width:520px;margin:0 auto">'
          '<div style="background:#1a1612;padding:20px 28px;border-radius:12px 12px 0 0">'
          '<span style="color:white;font-size:16px;font-weight:800">$sender</span></div>'
          '<div style="background:white;padding:28px;border-radius:0 0 12px 12px">'
          '<div style="background:#f7f4ef;border-radius:10px;padding:14px 18px;margin:0 0 20px;border-left:3px solid #e84c1e">'
          '<p style="margin:0;font-size:12px;color:#8a8070">Amount due</p>'
          '<p style="margin:4px 0;font-size:20px;font-weight:800;color:#e84c1e">'
          '\$$amountStr</p>'
          '<p style="margin:0;font-size:12px;color:#8a8070">Due: $due</p></div>'
          '<div style="font-size:14px;color:#3d3530;line-height:1.8;white-space:pre-wrap">$message</div>'
          '<p style="margin:20px 0 0;font-size:13px;color:#8a8070">Best regards,<br>'
          '<strong style="color:#1a1612">$sender</strong></p></div></div>';

      final res = await http.post(
        Uri.parse('$_baseUrl/api/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': toEmail,
          'toName': toName,
          'subject': 'Payment reminder — \$$amountStr due $due',
          'html': html,
          'type': 'chase',
        }),
      );
      print('[EmailService] Chase status: ${res.statusCode} ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('[EmailService] Chase error: $e');
      return false;
    }
  }
}