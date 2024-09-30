import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NotFoundUserScreen extends StatelessWidget {
  const NotFoundUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Center(
            child: Lottie.network(
              'https://lottie.host/098397ae-3f45-4928-9db8-bc1fb56fa9a9/pavnbqvDxv.json',
              width: 300,
              height: 300,
            ),
          ),
        ],
      )
    );
  }
}
