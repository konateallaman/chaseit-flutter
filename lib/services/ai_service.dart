import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';

class AiService {
  static const String _baseUrl = 'https://chaseit-api.vercel.app';

  static Future<String?> generateChaseMessage({
    required Invoice invoice,
    String senderName = '',
    String tone = 'gentle',
    String channel = 'email',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/chase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client': invoice.client,
          'amount': invoice.remaining,
          'due': invoice.due,
          'invoiceNum': invoice.num,
          'description': invoice.desc,
          'sender': senderName.isNotEmpty ? senderName : invoice.sender,
          'tone': tone.isNotEmpty ? tone : invoice.seq,
          'channel': channel,
          'chaseNum': invoice.chases + 1,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message'] as String?;
      }
      return null;
    } catch (e) {
      print('[AiService] Error: $e');
      return null;
    }
  }
}