import 'dart:async'; // For Timer
import 'dart:convert'; // For jsonEncode

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/OptionScreen.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added import for DeviceOrientation
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
  final Function(bool)? onVisibilityChanged;

  const ContentScreen({
    Key? key,
    this.src,
    this.userInfo,
    this.views,
    this.reactions,
    this.shares,
    required this.FileID,
    this.onVisibilityChanged,
  }) : super(key: key);

  @override
  ContentScreenState createState() => ContentScreenState();
}

class ContentScreenState extends State<ContentScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final ValueNotifier<bool> _likedNotifier = ValueNotifier<bool>(false);
  int? _currentUserId;
  DateTime? _lastTapTime;
  bool _showTouchIcon = false;
  bool _showPauseIcon = false;
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

      if (!mounted) return;

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          showControls: false,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        );
      });

      _videoPlayerController.play();
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await UserInfoProvider().getUserID();
    setState(() {});
  }

  Future<void> _reactToVideo() async {
    if (_currentUserId == null) return;

    final url = Uri.parse('http://10.0.2.2:5000/react');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
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
    setState(() {
      if (_videoPlayerController.value.isPlaying) {
        _videoPlayerController.pause();
        _showPauseIcon = true;
      } else {
        _videoPlayerController.play();
        _showPauseIcon = false;
      }
    });
  }

  void _handleDoubleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > Duration(milliseconds: 300)) {
      _lastTapTime = now;
      return;
    }

    _lastTapTime = now;
    _showTouchIcon = true;

    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(Duration(seconds: 1), () {
      setState(() => _showTouchIcon = false);
    });

    _resetIconTimer?.cancel();
    _resetIconTimer = Timer(Duration(seconds: 2), () {
      setState(() => _showTouchIcon = false);
    });

    _reactToVideo();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onVisibilityChanged != null) {
      widget.onVisibilityChanged!(true);
    }
  }

  @override
  void deactivate() {
    if (widget.onVisibilityChanged != null) {
      widget.onVisibilityChanged!(false);
    }
    super.deactivate();
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

  void playVideo() {
    if (_videoPlayerController.value.isInitialized) {
      _videoPlayerController.play();
    }
  }

  void pauseVideo() {
    if (_videoPlayerController.value.isInitialized) {
      _videoPlayerController.pause();
    }
  }

  bool isVideoPlaying() {
    return _videoPlayerController.value.isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    print("Building ContentScreen");
    print("_chewieController: ${_chewieController != null}");
    print(
        "Video initialized: ${_chewieController?.videoPlayerController.value.isInitialized}");

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (_chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized)
            _buildVideoPlayer()
          else
            _buildLoadingIndicator(),
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

  Widget _buildVideoPlayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final videoRatio = _videoPlayerController.value.aspectRatio;
        final screenRatio = constraints.maxWidth / constraints.maxHeight;

        Widget mediaWidget;
        if (videoRatio > 1) {
          // Media is 16:9 or wider
          // Calculate the height of the video/image
          double mediaHeight = constraints.maxWidth / videoRatio;
          // Calculate the height of the black bars
          double blackBarHeight = (constraints.maxHeight - mediaHeight) / 2;

          mediaWidget = Column(
            children: [
              Container(height: blackBarHeight, color: Colors.black),
              SizedBox(
                width: constraints.maxWidth,
                height: mediaHeight,
                child: _buildMediaContent(),
              ),
              Container(height: blackBarHeight, color: Colors.black),
            ],
          );
        } else {
          // Media is 9:16 or taller
          mediaWidget = SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / videoRatio,
                child: _buildMediaContent(),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: _handleSingleTap,
          onDoubleTap: _handleDoubleTap,
          child: Container(
            color: Colors.black,
            child: Center(child: mediaWidget),
          ),
        );
      },
    );
  }

  Widget _buildMediaContent() {
    if (_chewieController != null &&
        _videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else if (_videoPlayerController.value.hasError) {
      print(
          'Video player error: ${_videoPlayerController.value.errorDescription}');
      return Center(
          child:
              Text('Error: ${_videoPlayerController.value.errorDescription}'));
    } else if (widget.src != null &&
        widget.src!.toLowerCase().endsWith('.mp4')) {
      return _buildLoadingIndicator();
    } else if (widget.src != null) {
      return Image.network(
        widget.src!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(child: Text('Error loading image'));
        },
      );
    } else {
      return Center(child: Text('No media source provided'));
    }
  }

  Widget _buildAnimatedIcon(IconData icon) {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(milliseconds: 300),
        child: Icon(icon, color: Colors.lightBlueAccent, size: 100),
      ),
    );
  }
 
  Widget _buildLoadingIndicator() {
    return Center(
      child: Lottie.asset(
        'assets/Animated/loading.json',
        width: 150,
        height: 150,
      ),
    );
  }
}
