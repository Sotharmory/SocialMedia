import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lottie/lottie.dart';

class BlockList extends StatefulWidget {
  final int userId;

  BlockList({Key? key, required this.userId}) : super(key: key);

  @override
  _BlockListState createState() => _BlockListState();
}

class _BlockListState extends State<BlockList> {
  late Future<List<dynamic>> _blockedUsers;

  @override
  void initState() {
    super.initState();
    _blockedUsers = fetchBlockedUsers(widget.userId);
  }

  Future<List<dynamic>> fetchBlockedUsers(int userId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/list_blocked_users/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['blocked_users'];
    } else {
      throw Exception('Failed to load blocked users');
    }
  }

  Future<void> unblockUser(int blockedUserId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:5000/unblock'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': widget.userId, 'blocked_user_id': blockedUserId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _blockedUsers = fetchBlockedUsers(widget.userId); // Refresh the list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unblock user')),
      );
      throw Exception('Failed to unblock user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked Users',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.lightBlueAccent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _blockedUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final blockedUsers = snapshot.data!;
            if (blockedUsers.isEmpty) {
              return Column(
                children: [
                  SizedBox(
                    height: 100,
                  ),
                  Center(
                      child: Lottie.network('https://lottie.host/6db3079b-a76e-430d-9c45-d55372772f82/LSb9qHh1Ad.json',
                          height: 250,
                          width: 250)
                  ),
                  Text('You have not blocked any user !',
                    style: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold),
                  )
                ],
              );
            }
            return ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: blockedUsers[index]['profile_picture'] != null && blockedUsers[index]['profile_picture'].isNotEmpty
                              ? NetworkImage('http://10.0.2.2:5000/download/avatar/${blockedUsers[index]['profile_picture']}')
                              : AssetImage('assets/default_profile_pic.png') as ImageProvider,
                          child: blockedUsers[index]['profile_picture'] == null || blockedUsers[index]['profile_picture'].isEmpty
                              ? Icon(Icons.person, size: 30)
                              : null,
                        ),
                        SizedBox(width: 16),
                        // Full Name
                        Expanded(
                          child: Text(
                            blockedUsers[index]['full_name'] ?? 'Unknown User',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Unblock Button with Blue Background
                        ElevatedButton(
                          onPressed: () {
                            unblockUser(blockedUsers[index]['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent, // Set the background color
                          ),
                          child: Text(
                            'Unblock',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
