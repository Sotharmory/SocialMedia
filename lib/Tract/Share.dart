import 'package:flutter/material.dart';

class ShareThisAccount extends StatelessWidget {
  const ShareThisAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Adjust height as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share, size: 24), // Icon size
                const SizedBox(width: 8), // Space between icon and text
                const Text(
                  'Share This Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose how you want to share this account:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle the share action (e.g., share link)
                Navigator.pop(context); // Close the bottom sheet
                // Add logic to share the account here
              },
              child: const Text('Share via Link'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // Full-width button
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Handle the share action (e.g., via social media)
                Navigator.pop(context); // Close the bottom sheet
                // Add logic to share via social media here
              },
              child: const Text('Share on Social Media'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // Full-width button
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the bottom sheet
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
