import 'package:Doune/Screen/MenuPage.dart';
import 'package:flutter/material.dart';
import 'package:Doune/Widget/DraggableHandle.dart';
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BlockTractSheet extends StatelessWidget {
  final int userid; // User ID to block
  final UserInfoProvider userInfoProvider = UserInfoProvider(); // Initialize UserInfoProvider

  BlockTractSheet({Key? key, required this.userid}) : super(key: key);

  Future<void> _unfollowUser(BuildContext context) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final signedInID = sharedPreferences.getInt('user_id');

    if (signedInID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to sign in to unfollow this user.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'http://10.0.2.2:5000/unfollow';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'follower_id': signedInID,
          'followed_id': userid,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully unfollowed user.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unfollow user.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> blockUser(BuildContext context, int blockedUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool('isSignedIn') ?? false;

    if (!isSignedIn) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Not Logged In', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            content: Text('You must be logged in to block a user.', style: TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.lightBlueAccent,
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final currentUserId = await userInfoProvider.getUserID();
    final url = Uri.parse('http://10.0.2.2:5000/block');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': currentUserId,
          'blocked_user_id': blockedUserId,
        }),
      );

      if (response.statusCode == 201) {
        // Unfollow the user after blocking
        await _unfollowUser(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User blocked successfully')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage(isSignedIn: isSignedIn)),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DraggableHandle(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Block User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Icon(Icons.block, size: 24, color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to block this user?',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Blocking a user will prevent them from interacting with you. You can unblock them later if you choose.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => blockUser(context, userid),
            child: const Text('Block User'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the bottom sheet
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.blueAccent)),
          ),
          // Removed the "Unfollow User" button as requested
        ],
      ),
    );
  }
}
