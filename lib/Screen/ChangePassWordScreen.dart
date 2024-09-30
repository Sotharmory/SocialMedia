import 'dart:convert';

import 'package:Doune/BackEnd/ChangePassWord.dart';
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/BannedScreen.dart';
import 'package:Doune/Screen/MenuPage.dart';
import 'package:Doune/Utils/Snackbar.dart';
import 'package:Doune/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
class AuthService {
  static Future<bool> isUserSignedIn() async {
    return Future.value(true);
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  const ChangePasswordScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final userInfoProvider = UserInfoProvider();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Change Password"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [backgroundColor2, backgroundColor2, backgroundColor4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.03),
                  _buildHeader(),
                  SizedBox(height: size.height * 0.04),
                  _buildPasswordTextField(),
                  _buildConfirmPasswordTextField(),
                  SizedBox(height: size.height * 0.04),
                  _buildSubmitButton(size),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "Doune",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 37,
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "We will protect your private\ninformation, don’t be worried!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, color: textColor2, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildPasswordTextField() {
    return _myTextField(
      hint: "Enter new password",
      color: Colors.white,
      suffixIcon: Icons.privacy_tip_sharp,
      isPassword: true,
      controller: _passwordController,
    );
  }

  Widget _buildConfirmPasswordTextField() {
    return _myTextField(
      hint: "Confirm new password",
      color: Colors.white,
      suffixIcon: Icons.privacy_tip_sharp,
      isPassword: true,
      controller: _confirmPasswordController,
    );
  }

  Widget _myTextField({
    required String hint,
    required Color color,
    required IconData suffixIcon,
    required bool isPassword,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 19),
          suffixIcon: Icon(suffixIcon, color: color),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Size size) {
    return GestureDetector(
      onTap: _handleSubmit,
      child: Container(
        width: size.width,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFF98D0E7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            "Submit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> checkIfBanned(int userId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/check_ban/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['is_banned'] == true;
    } else {
      throw Exception('Failed to check ban status');
    }
  }

  Future<void> _handleSubmit() async {
    try {
      String password = _passwordController.text.trim();
      String confirmPassword = _confirmPasswordController.text.trim();

      if (password.isEmpty) {
        showErrorSnackbar(context, "Enter the new password");
        return;
      }
      if (confirmPassword.isEmpty) {
        showErrorSnackbar(context, "Enter the confirm password");
        return;
      }
      if (confirmPassword != password) {
        showErrorSnackbar(context, "Passwords do not match!");
        return;
      }

      // Call the API to change the password
      await _apiService.changePassword(widget.email, password);
      bool isSignedIn = await AuthService.isUserSignedIn();

      // Fetch user info and check if the user is banned
      final userInfo = await userInfoProvider.getUserInfo(widget.email);
      if (userInfo != null && userInfo.containsKey('UserID')) {
        final userId = userInfo['UserID'];
        print('test $userId');
        if (userId != null) {
          await userInfoProvider.saveUserID(userId);

          // Check if the user is banned
          bool isBanned = await checkIfBanned(userId);
          if (isBanned) {
            // Navigate to BannedScreen if the user is banned
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BannedScreen(userId: userId,)),
            );
            return;
          }
        }
      }

      // Save signed-in status if the user is not banned
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedIn', true);

      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(isSignedIn: isSignedIn),
        ),
      );
    } catch (e) {
      print('Error: $e');
      showErrorSnackbar(context, "An unexpected error occurred.");
    }
  }
}