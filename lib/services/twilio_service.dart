import 'package:http/http.dart' as http;
import 'dart:convert';

class TwilioService {
  static const accountSid = 'ACe7fa09f48846c0d773e8c9acffcf258b';
  static const authToken = '5bbeada8da3d31b9f50a1d7ee87a800f';
  static const whatsappFrom = 'whatsapp:+14155238886'; // Twilio Sandbox number

  static Future<void> sendWhatsAppMessage({
    required String to,
    required String messageBody,
  }) async {
    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {'From': whatsappFrom, 'To': 'whatsapp:$to', 'Body': messageBody},
    );

    if (response.statusCode == 201) {
      print('✅ WhatsApp message sent successfully!');
    } else {
      print('❌ Failed to send WhatsApp message: ${response.body}');
    }
  }
}
