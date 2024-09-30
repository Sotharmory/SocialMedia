import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String apiUrl = 'http://10.0.2.2:5000'; // Đặt URL của API của bạn ở đây

  Future<bool> checkBanStatus(int userId) async {
    final url = Uri.parse('$apiUrl/check_ban/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_banned'];
      } else if (response.statusCode == 404) {
        print('User not found');
        return false;
      } else {
        print('Failed to load ban status');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}