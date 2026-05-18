import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Paste your Resend API key here (starts with re_)
  static const String _resendKey = 're_79enthfk_8yJJK6pZPd1q75uZj6a1wD4F';

  static Future<bool> sendVerificationEmail({
    required String toEmail,
    required String toName,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'ChaseIt <onboarding@resend.dev>',
          'to': [toEmail],
          'subject': 'Your ChaseIt verification code',
          'html': _buildEmailHtml(toName, code),
        }),
      );

      print('[EmailService] Status: ${response.statusCode}');
      print('[EmailService] Response: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[EmailService] Error: $e');
      return false;
    }
  }

  static String _buildEmailHtml(String name, String code) => '''
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
    <h1 style="margin:0 0 8px;font-size:24px;font-weight:800;color:#1a1612">
      Verify your email
    </h1>
    <p style="margin:0 0 24px;font-size:15px;color:#8a8070;line-height:1.6">
      Hi $name, enter this 6-digit code in ChaseIt to activate your account.
    </p>
    <div style="background:#f7f4ef;border-radius:12px;padding:28px;text-align:center;margin:0 0 24px">
      <div style="font-size:48px;font-weight:800;letter-spacing:16px;color:#e84c1e;font-family:monospace">
        $code
      </div>
      <p style="margin:10px 0 0;font-size:12px;color:#8a8070">
        Expires in 10 minutes
      </p>
    </div>
    <p style="margin:0;font-size:13px;color:#c4bdb0">
      If you did not create a ChaseIt account, ignore this email.
    </p>
  </td></tr>
  <tr><td style="background:#f7f4ef;padding:20px 32px;border-top:1px solid #f0ece5">
    <p style="margin:0;font-size:12px;color:#c4bdb0;text-align:center">
      © 2026 ChaseIt · Invoice Automation
    </p>
  </td></tr>
</table>
</td></tr>
</table>
</body>
</html>''';
}