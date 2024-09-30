import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert'; // Add this import
import 'package:Doune/BackEnd/VideoAPIHandle.dart'; // Import the file where FileItem is defined

class MediaDisplayScreen extends StatefulWidget {
  final List<FileItem> videos;
  final int initialIndex;
  final bool user;

  const MediaDisplayScreen({
    required this.videos,
    required this.initialIndex,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  _MediaDisplayScreenState createState() => _MediaDisplayScreenState();
}

class _MediaDisplayScreenState extends State<MediaDisplayScreen> {
  late PageController _pageController;
  int currentIndex = 0;
  bool isFeatured = false;
  bool isPrivate = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
    _updateVideoStatus(currentIndex);
  }

  void _updateVideoStatus(int index) {
    _checkFeatured(widget.videos[index].fileId).then((featured) {
      setState(() {
        isFeatured = featured;
      });
    });
    _checkPrivate(widget.videos[index].fileId).then((private) {
      setState(() {
        isPrivate = private;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double displayWidth = MediaQuery.of(context).size.width;
    double displayHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index; // Cập nhật chỉ số hiện tại
                print('Current index = $currentIndex');
                _updateVideoStatus(index); // Cập nhật trạng thái video
              });
            },
            itemBuilder: (context, index) {
              final video = widget.videos[index];
              return Center(
                child: video.type == 'video'
                    ? VideoPlayerScreen(videoUrl: video.url)
                    : CachedNetworkImage(
                        imageUrl: video.url,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            Center(child: Icon(Icons.error)),
                        fit: BoxFit.cover,
                        width: displayWidth,
                        height: displayHeight,
                      ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          if (widget.user)
            Positioned(
              top: 40,
              right: 20,
              child: PopupMenuButton<int>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (index) {
                  if (index == 1) {
                    _checkFeatured(widget.videos[currentIndex].fileId)
                        .then((isFeatured) {
                      _showAlert(
                        context,
                        'Featured',
                        isFeatured
                            ? 'Do you want to unfeature this video?'
                            : 'Do you want to feature this video?',
                        'Cancel',
                        isFeatured ? 'Unfeature' : 'Feature',
                        () =>
                            _updateFeatured(widget.videos[currentIndex].fileId),
                        isFeatured,
                      );
                    });
                  } else if (index == 2) {
                    _showAlert(
                        context,
                        'Delete',
                        'Do you want to delete this video?',
                        'Cancel',
                        'Delete',
                        () => _deleteVideo(widget.videos[currentIndex].fileId));
                  } else if (index == 3) {
                    _checkPrivate(widget.videos[currentIndex].fileId)
                        .then((isPrivate) {
                      _showAlert(
                        context,
                        'Privacy',
                        isPrivate
                            ? 'Do you want to make this video public?'
                            : 'Do you want to make this video private?',
                        'Cancel',
                        isPrivate ? 'Make Public' : 'Make Private',
                        () =>
                            _updatePrivate(widget.videos[currentIndex].fileId),
                        isPrivate,
                      );
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Text('Featured'),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text('Delete'),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: Text('Private'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAlert(BuildContext context, String title, String message,
      String cancelText, String confirmText,
      [VoidCallback? onConfirm, bool? isFeatured]) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                cancelText,
                style: TextStyle(
                    color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
              child: Text(confirmText),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isFeatured == true
                    ? Colors.redAccent
                    : Colors.lightBlueAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateFeatured(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/updatefeatured'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'file_id': fileId,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseJson['message'])),
        );
        setState(() {
          isFeatured = !isFeatured;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update featured status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _updatePrivate(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/updateprivate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'file_id': fileId,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseJson['message'])),
        );
        setState(() {
          isPrivate = !isPrivate;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update private status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<bool> _checkFeatured(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/checkfeatured?file_id=$fileId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return responseJson['featured'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check featured status')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      return false;
    }
  }

  Future<bool> _checkPrivate(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/checkprivate?file_id=$fileId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        return responseJson['private'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check private status')),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      return false;
    }
  }

  Future<void> _deleteVideo(String fileId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/delete_video/$fileId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseJson['message'])),
        );
        Navigator.of(context).pop(); // Close the screen after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  List<IconData> listOfIcons = [
    Icons.visibility_outlined,
    Icons.remove_done,
    Icons.delete_outline,
    Icons.lock,
  ];

  List<String> listOfStrings = [
    'View',
    'Featured',
    'Delete',
    'Private',
  ];
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _controller.setLooping(true); // Lặp lại video
          _controller.play(); // Tự động phát video
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        color: Colors.black, // Đặt màu nền cho màn hình
        child: Center(
          child: _controller.value.isInitialized
              ? Stack(
                  children: [
                    // Xác định tỷ lệ khung hình cho video
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller
                            .value.aspectRatio, // Tỷ lệ khung hình động
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    ),
                    if (!_isPlaying) // Chỉ hiển thị biểu tượng khi không phát
                      Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.lightBlueAccent,
                          size: 60.0,
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Lottie.asset('assets/Animated/loading.json',
                      height: 100)),
        ),
      ),
    );
  }
}
