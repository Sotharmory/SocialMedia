import 'package:flutter/material.dart';
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white), // Customize the icon as needed
          SizedBox(width: 8), // Spacing between icon and text
          Expanded(child: Text(message)), // Ensure text doesn't overflow
        ],
      ),
      backgroundColor: Colors.red, // Customize the background color
      duration: Duration(seconds: 4), // Customize the duration
    ),
  );
}