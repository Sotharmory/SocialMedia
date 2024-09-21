import 'package:Doune/BackEnd/SignInBackEnd.dart'; // Import your SignInBackEnd class
import 'package:Doune/BackEnd/SignUpBackEnd.dart';
import 'package:Doune/Screen/ForgotPasswordOTPScreen.dart';
import 'package:Doune/Screen/SignInScreen.dart';
import 'package:Doune/Screen/SignUpScreen.dart';
import 'package:Doune/Utils/Snackbar.dart';
import 'package:Doune/Utils/colors.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final SignInBackEnd _signInBackEnd = SignInBackEnd();
  final SignUpBackEnd _signUpBackEnd = SignUpBackEnd();

  @override
  void dispose() {
    _emailController.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Forgot Password"),
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
                    "Get back your password with a little\nstep, should remember sign in next time!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 27, color: textColor2, height: 1.2),
                  ),
                  SizedBox(height: size.height * 0.04),
                  myTextField("Enter the email or username", Colors.white, Icons.email, false, _emailController),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignInScreen()),
                        );
                      },
                      child: Text(
                        "Sign In",
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
                      try {
                        String email = _emailController.text.trim();
                        String? emailError = _signInBackEnd.validateEmail(email);

                        if (emailError != null) {
                          showErrorSnackbar(context, emailError);
                          return;
                        }

                        String? asyncEmailError = await _signUpBackEnd.validateEmailAsync(email);
                        if (asyncEmailError == null) {
                          showErrorSnackbar(context, "Email does not exist.");
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordOTPScreen(email: email),
                          ),
                        );
                      } catch (e, stackTrace) {
                        // Print the error and stack trace for debugging
                        print('Error: $e');
                        print('StackTrace: $stackTrace');
                        showErrorSnackbar(context, "An unexpected error occurred.");
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
                          "Get Verify Code!",
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Image.asset(image, height: 35),
    );
  }

  Container myTextField(String hint, Color color, IconData suffixIcon, bool isPassword, TextEditingController controller) {
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
}
