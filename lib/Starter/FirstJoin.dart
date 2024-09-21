import 'Intro.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: IntroductionScreen(
        globalBackgroundColor: const Color(0xFF98D0E7),
        scrollPhysics: const BouncingScrollPhysics(),
        pages: [
          PageViewModel(
            titleWidget: const Text(
              "Share Your Love",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            body: "With a touch",
            image: Center(
              child: SizedBox(
                height: size.height * 0.3,
                width: size.width * 0.8,
                child: LottieBuilder.asset(
                  "assets/Animated/IntroFirst.json",
                  repeat: false, // Play animation once
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          PageViewModel(
            titleWidget: const Text(
              "Connect To Everyone",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            body: "With a click",
            image: Center(
              child: SizedBox(
                height: size.height * 0.6, // Increase height
                width: size.width * 0.9, // Increase width
                child: Lottie.asset(
                  "assets/Animated/IntroSecond.json",
                  fit: BoxFit.contain, // Ensure the Lottie animation fits well
                ),
              ),
            ),
          ),
          PageViewModel(
            titleWidget: const Text(
              "Start With Doune",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            body: "Doune will accompany you",
            image: Center(
              child: SizedBox(
                height: size.height * 0.4, // Increase height
                width: size.width * 0.8, // Increase width
                child: Lottie.asset(
                  "assets/Animated/IntroThird.json",
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
        next: const Icon(Icons.arrow_forward, color: Colors.white,),
        done: const Text(
          "Finished",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),

        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          color: Colors.grey,
          activeColor: Colors.white,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        onDone: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenIntro', true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SplashScreen(isSignedIn: false)),
          );
        },
      ),
    );
  }
}
