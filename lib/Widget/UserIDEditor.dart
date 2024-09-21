import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart'; // Import the Lottie package
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class UserIdEditorSheet extends StatefulWidget {
  final String userName; // Required full name
  final int userId; // Required user ID
  final String updateAt; // Last updated time in "DD/MM/YYYY" format

  const UserIdEditorSheet({
    Key? key,
    required this.userName,
    required this.userId,
    required this.updateAt,
  }) : super(key: key);

  @override
  _UserIdEditorState createState() => _UserIdEditorState();
}

class _UserIdEditorState extends State<UserIdEditorSheet> {
  late TextEditingController _fullNameController;
  bool _isNameValid = true; // Track name validity
  bool _isEditable = true; // Track if the TextField is editable
  DateTime? _lastUpdateDate;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.userName);
    _checkUpdateValidity();
  }

  void _checkUpdateValidity() {
    // Kiểm tra nếu updateAt không rỗng
    if (widget.updateAt.isNotEmpty) {
      DateFormat format = DateFormat("dd/MM/yyyy");
      try {
        _lastUpdateDate = format.parse(widget.updateAt);
      } catch (e) {
        print('Error parsing date: $e');
        _lastUpdateDate = null; // Đặt _lastUpdateDate về null nếu có lỗi
      }
    } else {
      _lastUpdateDate = null; // Nếu rỗng, đặt _lastUpdateDate về null
    }

    DateTime now = DateTime.now();
    // Kiểm tra nếu lastUpdateDate hợp lệ
    if (_lastUpdateDate != null &&
        now.difference(_lastUpdateDate!).inDays < 30) {
      _isEditable = false; // Disable editing if within 30 days
    } else {
      _isEditable = true; // Có thể chỉnh sửa nếu không có ngày hợp lệ
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _validateName(String value) async {
    setState(() {
      // Kiểm tra nếu không rỗng, độ dài từ 3 đến 12, và chỉ chứa chữ cái hoặc chữ cái và số
      _isNameValid = value.isNotEmpty &&
          value.length >= 3 &&
          value.length <= 12 &&
          (RegExp(r'^[a-zA-Z]+$').hasMatch(value) ||
              RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])[a-zA-Z0-9]+$')
                  .hasMatch(value));
    });

    // Kiểm tra xem tên người dùng đã tồn tại trong cơ sở dữ liệu chưa
    if (_isNameValid) {
      final exists = await _checkUsernameExists(value);
      setState(() {
        _isNameValid = !exists; // Nếu tồn tại, không hợp lệ
      });
    }
  }

// Hàm giả lập để kiểm tra tên người dùng tồn tại trong cơ sở dữ liệu
  Future<bool> _checkUsernameExists(String username) async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2:5000/get_user_name/$username'));

    if (response.statusCode == 200) {
      // Nếu có phản hồi 200, có nghĩa là tên người dùng đã tồn tại
      return true;
    } else {
      // Nếu không, tên người dùng không tồn tại
      return false;
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true, // Allows dismissing by tapping outside
      backgroundColor: Colors.white, // Set background color to white
      builder: (context) {
        // Calculate the date components
        DateTime nextChangeDate = _lastUpdateDate!.add(Duration(days: 30));
        String formattedDate = DateFormat("dd/MM/yyyy").format(nextChangeDate);
        List<String> dateParts = formattedDate.split('/');

        return Container(
          padding: const EdgeInsets.all(16.0),
          width: MediaQuery.of(context).size.width, // Full width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16), // Default text style
                  children: [
                    const TextSpan(
                        text: 'You can change Doune ID again at: ',
                        style: TextStyle(color: Colors.black)),
                    TextSpan(
                      text: dateParts[0], // Day (DD)
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const TextSpan(
                        text: '/', style: TextStyle(color: Colors.black)),
                    // Slash
                    TextSpan(
                      text: dateParts[1], // Month (MM)
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    const TextSpan(
                        text: '/', style: TextStyle(color: Colors.black)),
                    // Slash
                    TextSpan(
                      text: dateParts[2], // Year (YYYY)
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 20),
              // Add the Lottie animation here
              Lottie.network(
                'https://lottie.host/36dc8651-a54c-4ada-b03c-4dc4262890e7/J9PAG9R4ZV.json',
                height: 150, // Adjust height as needed
                width: 150, // Adjust width as needed
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.lightBlueAccent),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Change Your Doune ID'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Close the sheet
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your current Doune ID:',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
                Text(
                  _fullNameController.text,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                Icon(
                  _isNameValid ? Icons.check_circle : Icons.cancel,
                  color:
                      _isNameValid ? Colors.lightBlueAccent : Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fullNameController,
              maxLength: 12,
              // Limit input to 16 characters
              enabled: _isEditable,
              // Disable if not editable
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.lightBlueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.lightBlueAccent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.lightBlueAccent),
                ),
              ),
              onChanged: (value) {
                _validateName(value); // Validate name on change
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.updateAt.isNotEmpty)
                  Text(
                    'Last updated: ${widget.updateAt}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      _isEditable ? Colors.lightBlueAccent : Colors.grey,
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  onPressed: _isEditable
                      ? () {
                          String newFullName = _fullNameController.text;
                          if (_isNameValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.lightBlueAccent,
                                  content: Text(
                                    'Your Doune ID is change successfully!',
                                    style: TextStyle(color: Colors.white),
                                  )),
                            );
                            _saveUserId(widget.userId, newFullName, context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text(
                                    'Your Doune ID is not valid or is using by another person please try again!',
                                    style: TextStyle(color: Colors.white),
                                  )),
                            );
                          }
                        }
                      : () {
                          _showBottomSheet(
                              context); // Show bottom sheet if not editable
                        },
                  child: Text(
                    'Change',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Lottie animation
            Expanded(
              child: Lottie.network(
                'https://lottie.host/5245fa4b-ef4a-41ea-add7-8b3e0e1a6bf0/DvjRjpWkiP.json',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserId(
      int userId, String newUsername, BuildContext context) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:5000/update_username/$userId'),
      // Thay đổi đường dẫn
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': newUsername}), // Thay đổi trường JSON
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Đóng sheet sau khi lưu
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update username',
                style: TextStyle(color: Colors.redAccent))),
      );
    }
  }
}
