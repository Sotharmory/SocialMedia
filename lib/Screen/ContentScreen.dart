import 'dart:async'; // For Timer
import 'dart:convert'; // For jsonEncode

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/OptionScreen.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

class ContentScreen extends StatefulWidget {
  final String? src;
  final Map<String, dynamic>? userInfo;
  final int? views;
  final int? reactions;
  final int? shares;
  final String FileID;

  const ContentScreen({
    Key? key,
    this.src,
    this.userInfo,
    this.views,
    this.reactions,
    this.shares,
    required this.FileID,
  }) : super(key: key);

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final ValueNotifier<bool> _likedNotifier = ValueNotifier<bool>(false);
  int? _currentUserId;
  DateTime? _lastTapTime;
  bool _showTouchIcon = false;
  bool _showPauseIcon = false; // Track whether to show the pause icon
  Timer? _hideIconTimer;
  Timer? _resetIconTimer;

  @override
  void initState() {
    super.initState();
    initializePlayer();
    _loadCurrentUserId();
  }

  Future<void> initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.src!);
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true, // Start playback automatically
        looping: true, // Loop the video indefinitely
        showControls: false,
      );
      setState(() {});
    } catch (e, stackTrace) {
      print('Error initializing video player: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await UserInfoProvider().getUserID();
    setState(() {});
  }

  Future<void> _reactToVideo() async {
    if (_currentUserId == null) return;

    final url = 'http://10.0.2.2:5000/react'; // Replace with your API URL
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'file_id': widget.FileID,
        'user_id': _currentUserId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['message'] == 'Liked video') {
        _toggleLikeStatus();
      }
    }
  }

  void _handleSingleTap() {
    if (_videoPlayerController.value.isPlaying) {
      _videoPlayerController.pause();
      setState(() {
        _showPauseIcon = true; // Hiển thị icon khi video dừng
      });
    } else {
      _videoPlayerController.play();
      setState(() {
        _showPauseIcon = false; // Ẩn icon khi video phát
      });
    }
  }

  void _handleDoubleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > Duration(milliseconds: 300)) {
      _lastTapTime = now;
      return;
    }

    _lastTapTime = now;
    _showTouchIcon = true;

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        _showTouchIcon = false;
      });
    });

    _resetIconTimer?.cancel();
    _resetIconTimer = Timer(Duration(seconds: 2), () {
      setState(() {
        _showTouchIcon = false;
      });
    });

    _reactToVideo();
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _likedNotifier.dispose();
    _hideIconTimer?.cancel();
    _resetIconTimer?.cancel();
    super.dispose();
  }

  void _toggleLikeStatus() {
    _likedNotifier.value = !_likedNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? GestureDetector(
            onTap: _handleSingleTap,
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Chewie(controller: _chewieController!),
                ),
                if (_showTouchIcon)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _showTouchIcon ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        Icons.touch_app_rounded,
                        color: Colors.blueAccent,
                        size: 100,
                      ),
                    ),
                  ),
                if (_showPauseIcon)
                  Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.lightBlueAccent,
                      size: 100,
                    ),
                  ),
              ],
            ),
          )
              : Center(
            child: Lottie.asset(
              'assets/Animated/loading.json',
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: OptionsScreen(
              userInfo: widget.userInfo,
              views: widget.views,
              reactions: widget.reactions,
              shares: widget.shares,
              FileID: widget.FileID,
              currentUserId: _currentUserId ?? 0,
              likedNotifier: _likedNotifier,
            ),
          ),
        ],
      ),
    );
  }
}
