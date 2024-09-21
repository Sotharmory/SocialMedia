import 'package:http/http.dart' as http;
import 'dart:convert';

class VerifyOTP {
  final String baseUrl = "http://10.0.2.2:5000";

  Future<bool> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/verify-otp');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      print(responseBody);
      return true;
    } else {
      return false;
    }
  }
}
