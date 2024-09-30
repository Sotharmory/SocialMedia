import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class IdentityVerification extends StatefulWidget {
  @override
  _IdentityVerificationState createState() => _IdentityVerificationState();
}

class _IdentityVerificationState extends State<IdentityVerification> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _linkToArticle = '';
  List<XFile?> _mediaFiles = List.filled(4, null);
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/identity-verification'),
      );

      request.fields['FullName'] = _name;
      request.fields['Email'] = _email;
      request.fields['LinkToArticle'] = _linkToArticle;

      for (int i = 0; i < _mediaFiles.length; i++) {
        if (_mediaFiles[i] != null) {
          var file = await http.MultipartFile.fromPath('Image', _mediaFiles[i]!.path);
          request.files.add(file);
        }
      }

      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request sent successfully!')));
          _controller.forward(); // Play animation on success
        } else {
          throw Exception('Failed to send request');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred, please try again!')));
      } finally {
        setState(() {
          _isLoading = false;
        });
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
      _mediaFiles[index] = null; // Simply set to null
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Identity Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: Lottie.asset('assets/Animated/loading.json', width: 200, height: 200))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField('Full Name', (value) {
                if (value == null || value.isEmpty) return 'Full Name';
                return null;
              }, (value) => _name = value!),
              SizedBox(height: 10),
              _buildTextFormField('Email', (value) {
                if (value == null || value.isEmpty) return 'Please enter your email...';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email!';
                return null;
              }, (value) => _email = value!),
              SizedBox(height: 10),
              _buildTextFormField('Link to your article', (value) {
                if (value == null || value.isEmpty) return 'Please enter your information!';
                return null;
              }, (value) => _linkToArticle = value!, maxLines: 1),
              SizedBox(height: 10),
              Text('Provide identification documents such as passports\n national IDs, etc.'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildMediaPlaceholder(index)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _submitForm,
                child: Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              Lottie.network(
                'https://lottie.host/2c26df80-473c-45cc-8601-1be7cdfa5385/j15WKU94Qu.json',
                width: 400,
                height: 300,
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.forward();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(String label, String? Function(String?) validator, Function(String?) onSaved, {int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Colors.blue)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Colors.blueAccent)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide(color: Colors.grey)),
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
            if (_mediaFiles[index] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(_mediaFiles[index]!.path),
                  fit: BoxFit.cover,
                  width: 70,
                  height: 70,
                ),
              )
            else
              Center(child: Icon(Icons.add, color: Colors.grey)),
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
