import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void showSuccessAnimation(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Lottie.asset(
          'assets/Animated/success.json',
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              Navigator.of(context).pop(); // Close the page after the animation
            });
          },
        ),
      ),
    ),
    opaque: false,
    barrierColor: Colors.transparent, // Make sure the background is transparent
  ));
}