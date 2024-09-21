import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Doune/Starter/Intro.dart'; // Import your IntroScreen
import 'package:Doune/Starter/FirstJoin.dart'; // Import your SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isSignedIn = prefs.getBool('isSignedIn') ?? false;
  final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

  // Debug print
  print("isSignedIn in main.dart: $isSignedIn");
  print("hasSeenIntro in main.dart: $hasSeenIntro");

  runApp(MyApp(isSignedIn: isSignedIn, hasSeenIntro: hasSeenIntro));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  final bool hasSeenIntro;
  const MyApp({required this.isSignedIn, required this.hasSeenIntro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: hasSeenIntro
          ? SplashScreen(
              isSignedIn:
                  isSignedIn) // Show SplashScreen if IntroScreen has been seen
          : IntroScreen(), // Show IntroScreen otherwise
    );
  }
}
