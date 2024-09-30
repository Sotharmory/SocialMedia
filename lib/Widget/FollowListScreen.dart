import 'package:flutter/material.dart';
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:lottie/lottie.dart';
import 'package:Doune/Screen/OtherUserScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowListScreen extends StatefulWidget {
  final int userId;
  final bool isFollowers;

  const FollowListScreen({
    Key? key,
    required this.userId,
    required this.isFollowers,
  }) : super(key: key);

  @override
  _FollowListScreenState createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>>? users;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    users = await (widget.isFollowers
        ? UserInfoProvider().fetchFollowers(widget.userId)
        : UserInfoProvider().fetchFollowing(widget.userId));
    setState(() {});
  }

  Future<void> _toggleFollow(int userId, bool isFollowing) async {
    final followerId = widget.userId;
    final followedId =
        userId; // Update the variable name to match the server-side key

    // Log the IDs to verify they are correct
    print(
        'Toggling follow status: follower_id=$followerId, followed_id=$followedId');

    final url = isFollowing
        ? 'http://10.0.2.2:5000/unfollow'
        : 'http://10.0.2.2:5000/follow';

    final body = json.encode({
      'follower_id': followerId,
      'followed_id': followedId, // Update the key to match the server-side key
    });

    // Log the request body
    print('Request body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          for (var user in users!) {
            if (user['user_id'] == userId) {
              user['isFollowing'] = !user['isFollowing'];
              break; // Thoát khỏi vòng lặp
            }
          }
        });
      } else {
        // Log the response for debugging
        print(
            'Failed to toggle follow status: ${response.statusCode} ${response.body}');
        throw Exception('Failed to toggle follow status');
      }
    } catch (e) {
      // Log any exceptions that occur during the HTTP request
      print('Exception occurred: $e');
      throw Exception('Failed to toggle follow status');
    }
  }

  Future<void> _refuseFollower(int userId) async {
    final followerId = userId;
    final followedId = widget.userId;

    // Log the IDs to verify they are correct
    print(
        'Refusing follower: follower_id=$followedId, followed_id=$followerId');

    final url = 'http://10.0.2.2:5000/unfollow';

    final body = json.encode({
      'follower_id': followerId,
      'followed_id': followedId,
    });

    // Log the request body
    print('Request body: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          users!.removeWhere((user) => user['user_id'] == userId);
        });
      } else {
        // Log the response for debugging
        print(
            'Failed to refuse follower: ${response.statusCode} ${response.body}');
        throw Exception('Failed to refuse follower');
      }
    } catch (e) {
      // Log any exceptions that occur during the HTTP request
      print('Exception occurred: $e');
      throw Exception('Failed to refuse follower');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (users == null) {
      return Container(
        height: 100,
        child: Center(child: Lottie.asset('assets/Animated/loading.json')),
      );
    } else if (users!.isEmpty) {
      return Container(
        height: 100,
        child: Center(
          child: Lottie.network(
              'https://lottie.host/f52cb4c1-fe76-4650-984b-771ad2e1d225/ngs0lfBT1O.json'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: users!.length,
      itemBuilder: (context, index) {
        final user = users![index];

        // Đảm bảo trường isFollowing luôn được khởi tạo
        user['isFollowing'] = user['isFollowing'] ?? true; // Mặc định là true

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user['profile_picture']),
          ),
          title: Text(
            user['full_name'],
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              if (widget.isFollowers) {
                _refuseFollower(user['user_id']);
              } else {
                _toggleFollow(user['user_id'], user['isFollowing']);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isFollowers
                  ? Colors.redAccent
                  : (user['isFollowing']
                      ? Colors.redAccent
                      : Colors.blueAccent),
            ),
            child: Text(
              widget.isFollowers
                  ? 'Refuse'
                  : (user['isFollowing'] ? 'Unfollow' : 'Follow'),
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherUserScreen(UserId: user['user_id']),
              ),
            );
          },
        );
      },
    );
  }
}
