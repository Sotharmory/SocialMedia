import 'package:flutter/material.dart';

class ChangePassWordWhenSignIn extends StatelessWidget {
  const ChangePassWordWhenSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
        title: Text(
          'Change Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add some padding
        child: Column(
          children: [
            SizedBox(height: 20), // Add space before the text fields
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  borderSide: BorderSide(color: Colors.lightBlueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.white, // Background color of the text field
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding for a better look
              ),
              obscureText: true, // Hide password input
            ),
            SizedBox(height: 20), // Space between fields
            TextFormField(
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  borderSide: BorderSide(color: Colors.lightBlueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding for a better look
              ),
              obscureText: true, // Hide password input
            ),
            SizedBox(height: 20), // Space before the button
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  borderSide: BorderSide(color: Colors.lightBlueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Adjust padding for a better look
              ),
              obscureText: true, // Hide password input
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your password change logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
              ),
              child: Text(
                'Change Password',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
