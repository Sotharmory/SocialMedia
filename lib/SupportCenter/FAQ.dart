import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
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
          'FAQ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildFAQItem(
              question: 'What is Doune?',
              answer: 'Doune is a platform that provides ...',
            ),
            _buildFAQItem(
              question: 'How can I reset my password?',
              answer: 'To reset your password, go to the login page and click on "Forgot Password".',
            ),
            _buildFAQItem(
              question: 'What should I do if my account is banned?',
              answer: 'If your account is banned, please contact support for more information.',
            ),
            // Add more FAQ items here
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(question),
        childrenPadding: EdgeInsets.zero, // Remove default padding to avoid divider effect
        children: [
          Container(
            color: Colors.yellow.shade100, // Set background color to yellow
            padding: const EdgeInsets.all(16.0), // Padding around the text
            width: double.infinity, // Make sure the container takes full width
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
