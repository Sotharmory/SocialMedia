import 'dart:async'; // Import for Timer

import 'package:Doune/BackEnd/SendOTP.dart';
import 'package:Doune/BackEnd/VerifyOTP.dart'; // Import your VerifyOTP class
import 'package:Doune/Screen/ChangePassWordScreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordOTPScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _ForgotPasswordOTPScreenState createState() =>
      _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final SendOTP _sendOTP = SendOTP();
  final VerifyOTP _verifyOTPService = VerifyOTP();
  List<String> otp = ['', '', '', '']; // List to store OTP digits
  List<FocusNode> focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ]; // Focus nodes for each OTP input
  late Timer _timer; // Timer for countdown
  int _start = 60; // Countdown start time
  bool _isCountingDown = false; // Flag to check if countdown is active
  bool _isLoading = false;

  get email => null; // Flag to show loading indicator

  @override
  void initState() {
    super.initState(); // Send OTP when the screen is initialized
  }

  @override
  void dispose() {
    if (_isCountingDown) {
      _timer.cancel(); // Cancel timer if it's active
    }
    for (var node in focusNodes) {
      node.dispose(); // Dispose of focus nodes
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xfff7f6fb),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                    size: 32,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Lottie.network(
                  'https://lottie.host/e97c7fe7-e625-4264-a350-fd809e4049b9/Q1ZRGFp5jO.json',
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Verification',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Enter your verification code",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              Container(
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _textFieldOTP(index: 0),
                        _textFieldOTP(index: 1),
                        _textFieldOTP(index: 2),
                        _textFieldOTP(index: 3),
                      ],
                    ),
                    SizedBox(height: 22),
                    _isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _verifyOTP,
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all<Color>(
                                    Colors.white),
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.blueAccent),
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(14.0),
                                child: Text(
                                  'Verify',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(height: 18),
              GestureDetector(
                onTap: _isCountingDown
                    ? null
                    : sendOTP, // Disable if counting down
                child: Text(
                  _isCountingDown
                      ? "Wait $_start seconds to get OTP again"
                      : "Get Verify Code",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isCountingDown ? Colors.grey : Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldOTP({required int index}) {
    return Container(
      height: 85,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: TextField(
          focusNode: focusNodes[index],
          onChanged: (value) {
            if (value.length == 1 && index < otp.length) {
              setState(() {
                otp[index] = value;
              });
              if (index < otp.length - 1) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else {
                _verifyOTP();
              }
            } else if (value.isEmpty && index > 0) {
              setState(() {
                otp[index] = '';
              });
              FocusScope.of(context).requestFocus(focusNodes[index - 1]);
            }
          },
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counter: Offstage(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });

    String enteredOTP = otp.join();
    bool isValid = await _verifyOTPService.verifyOtp(widget.email, enteredOTP);

    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      // Navigate to the success screen or next step
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(
                  email: widget.email,
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  void sendOTP() {
    setState(() {
      _start = 60;
      _isCountingDown = true;
    });

    // Start the timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start > 0) {
        setState(() {
          _start--;
        });
      } else {
        setState(() {
          _isCountingDown = false;
        });
        _timer.cancel(); // Stop the timer when it reaches zero
      }
    });

    // Implement the logic to send the OTP code here
    _sendOTP
        .sendOtp(widget.email); // Use the email parameter from the constructor
  }
}
