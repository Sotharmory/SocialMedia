import 'package:Doune/Screen/SignInScreen.dart'; // Import your SignInScreen or appropriate screen
import 'package:Doune/Utils/colors.dart'; // Import your colors file
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AuthmeScreen extends StatelessWidget {
  AuthmeScreen({Key? key}) : super(key: key); // Corrected the constructor

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove the debug banner
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Background container with border radius and Lottie animation
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    color: primaryColor, // Assuming primaryColor is defined in colors.dart
                  ),
                ),
              ),
              // Lottie animation positioned above the background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: size.height * 0.53,
                  width: size.width,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Lottie.asset(
                      "assets/Animated/authme.json",
                      repeat: false,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Sign In button positioned below the Lottie animation
              Positioned(
                bottom: size.height * 0.1,
                left: 0,
                right: 0,
                child: Center(
                  child: MaterialButton(
                    minWidth: size.width * 0.6, // Responsive width
                    height: 50,
                    color: Color(0xFF98D0E7),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignInScreen(),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Adjust border radius as needed
                    ),
                    child: Text(
                      "Sign In",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
