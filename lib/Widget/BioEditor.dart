import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class BioEditorSheet extends StatefulWidget {
  final String bio; // Required bio
  final int userId; // Required user ID

  const BioEditorSheet({
    Key? key,
    required this.bio,
    required this.userId,
  }) : super(key: key);

  @override
  _BioEditorSheetState createState() => _BioEditorSheetState();
}

class _BioEditorSheetState extends State<BioEditorSheet> {
  late TextEditingController _bioController;
  bool _isEditable = true; // Track if the TextField is editable

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Edit Your Bio'),
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
            TextFormField(
              controller: _bioController,
              maxLength: 32, // Limit input to 255 characters
              enabled: _isEditable, // Disable if not editable
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
                hintText: 'Enter your new bio...',
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _isEditable ? Colors.lightBlueAccent : Colors.grey,
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                onPressed: _isEditable
                    ? () {
                        String newBio = _bioController.text;
                        _saveBio(widget.userId, newBio, context);
                      }
                    : null,
                child: const Text(
                  'Update Bio',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  Future<void> _saveBio(int userId, String newBio, BuildContext context) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:5000/update_bio/$userId'),
      headers: {'Content-Type': 'application/json;charset=UTF-8'},
      body: jsonEncode({'bio': newBio}), // Gửi 'bio' như một chuỗi Unicode
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Đóng sheet sau khi lưu
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update bio',
              style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }
  }
}
