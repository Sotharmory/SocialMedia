import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class SupportRequestForm extends StatefulWidget {
  @override
  _SupportRequestFormState createState() => _SupportRequestFormState();
}

class _SupportRequestFormState extends State<SupportRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _message = '';
  List<XFile?> _mediaFiles = List.filled(4, null);
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/support-request'),
      );

      request.fields['FullName'] = _name;
      request.fields['Email'] = _email;
      request.fields['Message'] = _message;

      for (int i = 0; i < _mediaFiles.length; i++) {
        if (_mediaFiles[i] != null) {
          var file = await http.MultipartFile.fromPath(
            'Image',
            _mediaFiles[i]!.path,
          );
          request.files.add(file);
        }
      }

      var response = await request.send();

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yêu cầu đã được gửi thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi, vui lòng thử lại!')),
        );
      }
    }
  }

  Future<void> _pickMedia(int index) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFiles[index] = pickedFile;
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles[index] = null;
      for (int i = index; i < _mediaFiles.length - 1; i++) {
        _mediaFiles[i] = _mediaFiles[i + 1];
      }
      _mediaFiles[_mediaFiles.length - 1] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Support Request Form',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset('assets/Animated/loading.json', width: 200, height: 200),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextFormField('Full Name', (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full Name';
                  }
                  return null;
                }, (value) {
                  _name = value!;
                }),
                SizedBox(height: 10),
                _buildTextFormField('Email', (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email...';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email!';
                  }
                  return null;
                }, (value) {
                  _email = value!;
                }),
                SizedBox(height: 10),
                _buildTextFormField('Message', (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message!';
                  }
                  return null;
                }, (value) {
                  _message = value!;
                }, maxLines: 4),
                SizedBox(height: 10),
                Text(' Provide identification documents such as passports\n national IDs, etc.'),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < 4; i++) _buildMediaPlaceholder(i),
                  ],
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: _submitForm,
                  child: Text(
                    'Send',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20), // Thêm khoảng cách trước Lottie
                Lottie.network(
                  'https://lottie.host/fef2b1ad-e0b8-475e-8e63-e16d8a82b982/Xm1bG25Iyu.json',
                  width: 400,
                  height: 300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(String label, String? Function(String?) validator, Function(String?) onSaved, {int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
      maxLines: maxLines,
    );
  }

  Widget _buildMediaPlaceholder(int index) {
    return GestureDetector(
      onTap: () => _pickMedia(index),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.lightBlueAccent),
        ),
        child: Stack(
          children: [
            _mediaFiles[index] != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                File(_mediaFiles[index]!.path),
                fit: BoxFit.cover,
                width: 70,
                height: 70,
              ),
            )
                : Center(child: Icon(Icons.add, color: Colors.grey)),
            if (_mediaFiles[index] != null)
              Positioned(
                left: 40,
                bottom: 40,
                child: IconButton(
                  icon: Icon(Icons.clear_outlined, color: Colors.black54),
                  onPressed: () => _removeMedia(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
