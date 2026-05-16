import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';

class AiService {
  // Your Vercel backend URL — update after deploying
  static const String _baseUrl = 'https://your-chaseit-app.vercel.app';

  static Future<String> generateChaseMessage({
    required Invoice invoice,
    required String channel, // email, sms, whatsapp
  }) async {
    final chaseNum = invoice.chases + 1;
    final tone = chaseNum == 1
        ? 'polite and friendly'
        : chaseNum == 2
            ? 'firm but professional'
            : 'serious and urgent';

    final overdueDays = invoice.daysOverdue;
    final amountStr = '\$${invoice.remaining.toStringAsFixed(2)}';

    final prompts = {
      'email': '''Write a $tone invoice follow-up email.
Client: ${invoice.client}, Amount owed: $amountStr, Due: ${invoice.due},
${overdueDays > 0 ? '$overdueDays days overdue' : 'due soon'}, 
Description: ${invoice.desc.isNotEmpty ? invoice.desc : 'services rendered'}, 
From: ${invoice.sender.isNotEmpty ? invoice.sender : 'your business'}.
Chase #$chaseNum. 3-4 short paragraphs, clear CTA. Email body only, no subject line.''',
      'sms': '''Write a $tone SMS invoice reminder under 160 chars.
Client: ${invoice.client}, Owes: $amountStr, 
${overdueDays > 0 ? '$overdueDays days overdue' : 'due soon'}.
Direct, clear next step. Just the SMS text.''',
      'whatsapp': '''Write a $tone WhatsApp message for unpaid invoice.
Client: ${invoice.client}, Owes: $amountStr,
${overdueDays > 0 ? '$overdueDays days overdue' : 'due soon'},
From: ${invoice.sender.isNotEmpty ? invoice.sender : 'your business'}.
Conversational, 2-3 sentences, emoji ok. Just the message.''',
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-5',
          'max_tokens': 600,
          'messages': [
            {'role': 'user', 'content': prompts[channel]},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String? ?? '';
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate message: $e');
    }
  }
}
