import 'dart:convert';

import 'package:Doune/BackEnd/SignInBackEnd.dart';
import 'package:Doune/Screen/OtherUserScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OptionsScreen extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  final int? views;
  final int? reactions;
  final int? shares;
  final String? FileID;
  final int currentUserId;
  final ValueNotifier<bool>? likedNotifier;

  OptionsScreen({
    this.userInfo,
    this.views,
    this.reactions,
    this.shares,
    required this.FileID,
    required this.currentUserId,
    this.likedNotifier,
  });

  @override
  _OptionsScreenState createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  bool _isFollowing = false;
  bool _hasLiked = false;
  late VoidCallback _likedListener;

  @override
  void initState() {
    super.initState();
    _loadStatus();

    _likedListener = () {
      setState(() {
        _hasLiked = widget.likedNotifier?.value ?? false;
      });
    };

    widget.likedNotifier?.addListener(_likedListener);
  }

  @override
  void dispose() {
    widget.likedNotifier?.removeListener(_likedListener); // Xóa listener
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final videoUserId = widget.userInfo?['UserId'] ?? 0;
    final videoFileId = widget.FileID ?? '';

    if (videoFileId.isEmpty) return;

    try {
      final isFollowing = await _checkIfFollowing(videoUserId);
      final hasLiked = await _checkReactionStatus(videoFileId);

      if (!mounted) return; // Kiểm tra mounted

      setState(() {
        _isFollowing = isFollowing;
        _hasLiked = hasLiked;
        if (widget.likedNotifier != null) {
          widget.likedNotifier?.value = _hasLiked;
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to load status.');
      }
    }
  }

  Future<bool> _checkIfFollowing(int followedUserId) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final signedUserID = sharedPreferences.getInt('user_id');
    if (signedUserID == null) return false;

    final url = 'http://10.0.2.2:5000/check';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'follower_id': signedUserID,
        'followed_user_id': followedUserId,
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['isFollowing'] ?? false;
    } else {
      throw Exception('Failed to check follow status');
    }
  }

  Future<bool> _checkReactionStatus(String fileId) async {
    final url =
        'http://10.0.2.2:5000/checkreaction?file_id=$fileId&user_id=${widget.currentUserId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] == true;
      } else {
        throw Exception('Failed to check reaction status.');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
      return false;
    }
  }

  Future<void> _followUser() async {
    final videoUserId = widget.userInfo?['UserId'] ?? 0;
    if (videoUserId == 0) {
      _showErrorSnackbar('User ID is not available.');
      return;
    }

    final sharedPreferences = await SharedPreferences.getInstance();
    final signedUserID = sharedPreferences.getInt('user_id');
    if (signedUserID == null) {
      _showErrorSnackbar('You need to sign in to follow this user.');
      return;
    }

    final url = 'http://10.0.2.2:5000/follow';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'follower_id': signedUserID,
          'followed_id': videoUserId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _isFollowing = true;
        });
        _showSuccessSnackbar('Successfully followed user.');
      } else if (response.statusCode == 400) {
        _showErrorSnackbar('You are already following this user.');
      } else {
        _showErrorSnackbar('Failed to follow user.');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  Future<void> _unfollowUser() async {
    final videoUserId = widget.userInfo?['UserId'] ?? 0;
    if (videoUserId == 0) return;

    final sharedPreferences = await SharedPreferences.getInstance();
    final signedUserID = sharedPreferences.getInt('user_id');
    if (signedUserID == null) {
      _showErrorSnackbar('You need to sign in to unfollow this user.');
      return;
    }

    final url = 'http://10.0.2.2:5000/unfollow';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'follower_id': signedUserID,
          'followed_id': videoUserId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFollowing = false;
        });
        _showSuccessSnackbar('Successfully unfollowed user.');
      } else {
        _showErrorSnackbar('Failed to unfollow user.');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  Future<void> _reactToVideo() async {
    final videoFileId = widget.FileID;

    if (videoFileId == null) {
      _showErrorSnackbar('File ID is not available.');
      return;
    }

    final url = _hasLiked
        ? 'http://10.0.2.2:5000/unreact'
        : 'http://10.0.2.2:5000/react';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file_id': videoFileId,
          'user_id': widget.currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _hasLiked = !_hasLiked;
        });
        if (widget.likedNotifier != null) {
          widget.likedNotifier?.value = _hasLiked;
        }
      } else {
        _showErrorSnackbar('Failed to update reaction.');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.userInfo?['ProfilePicture'] != null
        ? 'http://10.0.2.2:5000/download/avatar/${widget.userInfo?['ProfilePicture']}'
        : null;

    final videoUserId = widget.userInfo?['UserId'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Info and Follow Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 110),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OtherUserScreen(UserId: videoUserId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(Icons.person, size: 18)
                              : null,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        widget.userInfo?['FullName'] ?? 'Unknown User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      if (widget.userInfo?["Verified"] == true)
                        Icon(Icons.verified, size: 20, color: Colors.blue),
                      SizedBox(width: 10),
                      if (widget.currentUserId != videoUserId)
                        TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              _isFollowing
                                  ? Colors.grey
                                  : Colors.lightBlueAccent,
                            ),
                            padding: WidgetStateProperty.all(
                              EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                            ),
                          ),
                          onPressed: () {
                            if (_isFollowing) {
                              _unfollowUser();
                            } else {
                              _followUser();
                            }
                          },
                          child: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
              // Reaction and Stats
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.touch_app_rounded,
                      size: 35,
                      color: _hasLiked ? Colors.blueAccent : Colors.white,
                    ),
                    onPressed: () async {
                      bool isSignedIn = await SignInBackEnd().isSignedIn();
                      if (isSignedIn) {
                        _reactToVideo();
                      } else {
                        _showErrorSnackbar(
                            'Please sign in to react to the video!');
                      }
                    },
                  ),
                  Text('${widget.reactions ?? 0}',
                      style: TextStyle(color: Colors.white)),
                  SizedBox(height: 25),
                  Icon(Icons.ios_share_outlined, size: 30, color: Colors.white),
                  Text('${widget.shares ?? 0}',
                      style: TextStyle(color: Colors.white)),
                  SizedBox(height: 25),
                  Icon(Icons.visibility, size: 30, color: Colors.white),
                  Text('${widget.views ?? 0}',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
