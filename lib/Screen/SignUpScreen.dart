import 'package:Doune/BackEnd/SignUpBackEnd.dart';
import 'package:Doune/Screen/SignInScreen.dart';
import 'package:Doune/Screen/VerifyScreen.dart';
import 'package:Doune/Utils/Snackbar.dart';
import 'package:Doune/Utils/Utils.dart';
import 'package:Doune/Utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final SignUpBackEnd _signUpBackEnd = SignUpBackEnd();

  DateTime? _selectedDate; // Nullable DateTime to handle default "Please enter your birthday"

  @override
  void initState() {
    super.initState();
    _dateController.text = "Please enter your birthday"; // Set default hint text
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _dateController.text = DateFormat("dd-MM-yyyy").format(_selectedDate!);
    });
  }

  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Sign Up"),
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
                    "Everyone is sharing their love\nCreate a new account now!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 27, color: textColor2, height: 1.2),
                  ),
                  SizedBox(height: size.height * 0.05),
                  Utils.myTextField("Enter email", Colors.white, Icons.email, false, _emailController),
                  Utils.myTextField(
                    "Password",
                    Colors.black26,
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    _obscureText,
                    _passwordController,
                    _togglePasswordVisibility
                  ),

                  TextFormField(
                    validator: (value) {
                      if (_selectedDate == null) {
                        return "Select your Birthday";
                      }
                      return null; // Return null if validation succeeds
                    },
                    controller: _dateController,
                    cursorColor: Colors.lightBlueAccent,
                    readOnly: true, // Make the TextFormField read-only
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) => Container(
                          height: 300, // Adjust height as needed
                          child: CupertinoDatePicker(
                            backgroundColor: Colors.transparent,
                            initialDateTime: _selectedDate ?? DateTime.now(),
                            onDateTimeChanged: (DateTime value) {
                              _updateDate(value);
                            },
                            use24hFormat: true,
                            mode: CupertinoDatePickerMode.date,
                          ),
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );

                          if (pickedDate != null && pickedDate != _selectedDate) {
                            _updateDate(pickedDate);
                          }
                        },
                        icon: Icon(Icons.calendar_today_sharp),
                      ),
                      hintText: _selectedDate == null
                          ? "Please enter your birthday"
                          : DateFormat("dd-MM-yyyy").format(_selectedDate!),
                      hintStyle: TextStyle(
                        color: Colors.grey, // Change hint text color here
                        fontSize: 20,       // Adjust font size if needed
                      ),
                      errorStyle: TextStyle(color: Colors.redAccent),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.blueAccent, width: 3.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
                  GestureDetector(
                    onTap: () async {
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();
                      String dateofbirth = _selectedDate != null ? DateFormat("yyyy-MM-dd").format(_selectedDate!) : ''; // Use ISO 8601 format

                      // Synchronous validations
                      String? emailError = _signUpBackEnd.validateEmail(email);
                      String? passwordError = _signUpBackEnd.validatePassword(password);
                      String? dateofbirthError = _signUpBackEnd.validateDateOfBirth(dateofbirth);

                      if (emailError != null) {
                        showErrorSnackbar(context, emailError);
                        return;
                      }

                      if (passwordError != null) {
                        showErrorSnackbar(context, passwordError);
                        return;
                      }

                      if (dateofbirthError != null) {
                        showErrorSnackbar(context, dateofbirthError);
                        return;
                      }

                      // Asynchronous email validation
                      String? asyncEmailError = await _signUpBackEnd.validateEmailAsync(email);
                      if (asyncEmailError != null) {
                        showErrorSnackbar(context, asyncEmailError);
                        return;
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerifyScreen(
                            email: email,
                            password: password, // Pass the password
                            dateOfBirth: dateofbirth, // Pass the formatted date of birth
                          ),
                        ),
                      );
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
                          "Sign Up",
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
                        width: size.width * 0.3,
                        color: Colors.black12,
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.06),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Utils.socialIcon("images/google.png"),
                      Utils.socialIcon("images/apple.png"),
                      Utils.socialIcon("images/facebook.png"),
                    ],
                  ),
                  SizedBox(height: size.height * 0.07),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignInScreen()),
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Already a member? ",
                        style: TextStyle(
                          color: textColor2,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign In",
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
}


