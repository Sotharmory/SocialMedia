import 'package:Doune/Screen/SupportCenterScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BannedScreen extends StatefulWidget {
  final int userId;

  const BannedScreen({super.key, required this.userId});

  @override
  _BannedScreenState createState() => _BannedScreenState();
}

class _BannedScreenState extends State<BannedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? banReason;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _loadAnimation();
    _fetchBanReason(); // Fetch the ban reason on initialization
  }

  Future<void> _loadAnimation() async {
    await _controller.forward().then((_) {
      _controller.stop();
    });
  }

  Future<void> _fetchBanReason() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/user/${widget.userId}/ban-reason'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (data['ban_reason'] != null) {
          banReason = data['ban_reason'];
        } else {
          banReason = "No reason provided";
        }
      });
    } else {
      setState(() {
        banReason = "Error fetching ban reason.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _contactSupport() {
    // Navigate to support screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupportCenterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.lightBlueAccent,
        title: const Text(
          'Account Banned',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Lottie.network(
              'https://lottie.host/19bcff5d-e80b-463a-a3ff-37b80aa466e0/m5EOtcUCZW.json',
              height: 350,
              width: 200,
            ),
            const SizedBox(height: 20),
            if (banReason != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'You have been banned for reason: ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextSpan(
                        text: banReason!,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'If this is a misunderstanding or you want to appeal, contact us at Doune ',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  TextSpan(
                    text: 'account support center',
                    style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()..onTap = _contactSupport,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Add some space before the button
            ElevatedButton(
              onPressed: _contactSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Background color
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Padding for the button
              ),
              child: Text(
                'Contact Support',
                style: TextStyle(color: Colors.white, fontSize: 15,fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
