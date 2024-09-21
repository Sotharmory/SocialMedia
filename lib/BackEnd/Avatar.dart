import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> uploadAvatar(String email, String filePath) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://10.0.2.2:5000/upload-avatar'), // Địa chỉ API
  );

  request.fields['email'] = email; // Thêm email vào request
  request.files.add(await http.MultipartFile.fromPath('file', filePath));

  var response = await request.send();

  if (response.statusCode == 200) {
    // Phân tích dữ liệu JSON từ phản hồi
    var responseData = await response.stream.bytesToString();
    return jsonDecode(responseData);
  } else {
    print('Failed to upload avatar: ${response.statusCode}');
    return null;
  }
}