import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ClipRRect(borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 500,
              width: 380,
              color: Colors.brown,
            )
        ),
      ),
    );
  }
}
