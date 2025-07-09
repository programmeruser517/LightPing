import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class WhatsAppService {
  // CallMeBot API endpoint for WhatsApp messages
  static const String _callMeBotApiUrl = 'https://api.callmebot.com/whatsapp.php';
  
  // Bot phone number that users need to add to their contacts
  static const String botPhoneNumber = '+34 644 87 21 57';
  
  // List of various messages to rotate through
  static const List<String> _messageVariations = [
    'Light Ping Detected! A change in light intensity has been detected 🔦',
    'Alert! Your LightPing app has detected a light change 💡',
    'LightPing notification: Light change detected at your location 🌟',
    'Light Ping Alert: Someone may have turned on a light 🔆',
    'LightPing: A light source has been detected in your monitored area ✨'
  ];
  
  // Random generator for message variations
  static final Random _random = Random();
  
  /// Sends a WhatsApp message using the CallMeBot API
  /// Returns true if successful, false otherwise
  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String apiKey,
    String? customMessage,
  }) async {
    try {
      // Ensure phone number is in the correct format (E.164)
      // Remove any non-digit characters except the leading '+'
      final cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Select a random message if custom message is not provided
      final message = customMessage ?? _messageVariations[_random.nextInt(_messageVariations.length)];
      
      // URL encode the message
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create the API URL
      final apiUrl = '$_callMeBotApiUrl?phone=$cleanedPhoneNumber&text=$encodedMessage&apikey=$apiKey';
      
      // Send GET request to CallMeBot API
      final response = await http.get(Uri.parse(apiUrl));
      
      // Check if the message was successfully sent
      if (response.statusCode == 200) {
        final responseBody = response.body.toLowerCase();
        if (responseBody.contains('message queued') || responseBody.contains('success')) {
          print('WhatsApp message sent successfully to $cleanedPhoneNumber');
          return true;
        } else {
          print('Failed to send WhatsApp message: ${response.body}');
          return false;
        }
      } else {
        print('Failed to send WhatsApp message. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      return false;
    }
  }
  
  /// Get activation instructions for CallMeBot WhatsApp API
  static String getActivationInstructions() {
    return '''To use WhatsApp notifications with LightPing:

1. Add this phone number to your contacts: $botPhoneNumber (Name it "LightPing Bot")

2. Send "I allow callmebot to send me messages" to this contact via WhatsApp

3. Wait to receive your API key (usually within 2 minutes)

4. Enter the API key below to complete setup''';
  }
}
