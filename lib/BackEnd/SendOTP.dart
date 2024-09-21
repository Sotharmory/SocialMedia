import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendOTP with ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:5000"; // Your API base URL

  Future<bool> sendOtp(String email) async {
    final url = Uri.parse('$baseUrl/send-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'email': email}), // Include email in the request body
      );

      if (response.statusCode == 200) {
        // OTP sent successfully
        print('OTP sent successfully to $email');
        return true;
      } else {
        // Handle error response
        print('Failed to send OTP: ${response.body}');
        return false;
      }
    } catch (error) {
      // Handle network error
      print('Error occurred while sending OTP: $error');
      return false;
    }
  }
}
