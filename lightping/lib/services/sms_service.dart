import 'dart:convert';
import 'package:http/http.dart' as http;

class TextBeltSmsService {
  // TextBelt API endpoint (free tier)
  static const String _textBeltApiUrl = 'https://textbelt.com/text';
  
  // Maximum number of free SMS per day using the textbelt_text API key is 1
  static const String _apiKey = 'textbelt_text'; // Free API key
  
  /// Sends an SMS using the TextBelt API
  /// Returns true if successful, false otherwise
  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Ensure phone number is in the correct format (E.164)
      // Remove any non-digit characters except the leading '+'
      final cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Send POST request to TextBelt API
      final response = await http.post(
        Uri.parse(_textBeltApiUrl),
        body: {
          'phone': cleanedPhoneNumber,
          'message': message,
          'key': _apiKey,
        },
      );
      
      // Parse response
      final responseData = json.decode(response.body);
      
      // Check if the message was successfully queued
      if (responseData['success'] == true) {
        print('SMS sent successfully! TextBelt quota remaining: ${responseData['quotaRemaining']}');
        return true;
      } else {
        print('Failed to send SMS: ${responseData['error']}');
        return false;
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }
}
