import 'package:Doune/SupportCenter/IdentityVerification.dart';
import 'package:Doune/SupportCenter/SupportRequestForm.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:Doune/SupportCenter/FAQ.dart'; // Import your FAQ screen

class SupportCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.lightBlueAccent,
        title: const Text(
          'Support Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Lottie animation
            Lottie.network(
              'https://lottie.host/8ecb83ef-f9f4-4e32-a320-f4946d836e92/okeJAVtSey.json',
              height: 200,
            ),
            const SizedBox(height: 20),
            _buildSupportOption(context, 'FAQ', () {
              // Navigate to FAQ screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQScreen()),
              );
            }),
            _buildDivider(),
            _buildSupportOption(context, 'Support Request Form', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportRequestForm()),
              );
            }),

            _buildDivider(),
            _buildSupportOption(context, 'Identity Verification', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => IdentityVerification()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(BuildContext context, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1);
  }
}
