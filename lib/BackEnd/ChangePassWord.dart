import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<void> changePassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        // Handle successful password change
        var responseBody = jsonDecode(response.body);
        if (!responseBody['success']) {
          throw Exception(responseBody['message']);
        }
      } else {
        // Handle different status codes and provide appropriate messages
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      print('Error changing password: $e');
      throw Exception('Failed to change password');
    }
  }
}
