import 'package:flutter/material.dart';
import 'dart:async';
import '../Screen/MenuPage.dart';

class SplashScreen extends StatefulWidget {
  final bool isSignedIn;
  const SplashScreen({required this.isSignedIn, Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid any callbacks after dispose
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 1), _navigateToHome);
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(isSignedIn: widget.isSignedIn),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double imageSize = size.shortestSide * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFF98D0E7),
      body: Center(
        child: SizedBox(
          height: imageSize,
          width: imageSize,
          child: Image.asset(
            'assets/doune.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}