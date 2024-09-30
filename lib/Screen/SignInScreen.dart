import 'dart:convert';

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/BackEnd/SignInBackEnd.dart'; // Import your SignInBackEnd class
import 'package:Doune/Screen/BannedScreen.dart';
import 'package:Doune/Screen/ForgotPasswordScreen.dart';
import 'package:Doune/Screen/MenuPage.dart';
import 'package:Doune/Screen/SignUpScreen.dart';
import 'package:Doune/Utils/Snackbar.dart';
import 'package:Doune/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SignInBackEnd _signInBackEnd = SignInBackEnd();
  final userInfoProvider = UserInfoProvider();

  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Quay về trang trước
          },
        ),
        title: Text(
          "Sign In",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              backgroundColor2,
              backgroundColor2,
              backgroundColor4,
            ],
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
                    "Share your story and connect\nto everyone!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 27, color: textColor2, height: 1.2),
                  ),
                  SizedBox(height: size.height * 0.04),
                  myTextField("Enter the email or username", Colors.white, Icons.email, false, _emailController),
                  myTextField("Password", Colors.black26, _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, true, _passwordController, _togglePasswordVisibility),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        "Forgot Password?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
              GestureDetector(
                  onTap: () async {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    // Validate email and password
                    String? emailError = _signInBackEnd.validateEmail(email);
                    String? passwordError = _signInBackEnd.validatePassword(password);

                    if (emailError != null) {
                      showErrorSnackbar(context, emailError);
                      return;
                    }

                    if (passwordError != null) {
                      showErrorSnackbar(context, passwordError);
                      return;
                    }

                    bool success = await _signInBackEnd.signIn(email, password);
                    if (success) {
                      final userInfo = await userInfoProvider.getUserInfo(email);
                      if (userInfo != null && userInfo.containsKey('UserID')) {
                        final userId = userInfo['UserID'];
                          // Check if the user is banned
                          bool isBanned = await checkIfBanned(userId);
                          if (isBanned) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => BannedScreen(userId: userId,)),
                            );
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isSignedIn', true);
                            if (userId != null) {
                              // Save user ID locally
                              await userInfoProvider.saveUserID(userId);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomePage(isSignedIn: true)),
                            );
                          }
                        }
                      }
                    } else {
                      String invalidMessageSignIn = "Email or password is incorrect!";
                      showErrorSnackbar(context, invalidMessageSignIn);
                    }
                  },
                    child: Container(
                      width: size.width,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF98D0E7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.06),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 2,
                        width: size.width * 0.2,
                        color: Colors.black12,
                      ),
                      Text(
                        "  Or continue with   ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor2,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        height: 2,
                        width: size.width * 0.2,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.06),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      socialIcon("images/google.png"),
                      socialIcon("images/apple.png"),
                      socialIcon("images/facebook.png"),
                    ],
                  ),
                  SizedBox(height: size.height * 0.07),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Not a member? ",
                        style: TextStyle(
                          color: textColor2,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                            text: "Register now",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container socialIcon(String image) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          FacebookAuthService().loginWithFacebook();
        },
        child: Image.asset(
          image,
          height: 35,
        ),
      ),
    );
  }

  Container myTextField(String hint, Color color, IconData suffixIcon, bool isPassword, TextEditingController controller, [VoidCallback? onSuffixIconPressed]) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 10,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 19,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(suffixIcon, color: color),
            onPressed: onSuffixIconPressed,
          )
              : Icon(suffixIcon, color: color),
        ),
      ),
    );
  }
}
