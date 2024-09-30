import 'dart:async';
import 'dart:convert';

import 'package:Doune/Screen/ContentScreen.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> videos = [];
  bool isLoading = true;
  Timer? _timer;
  int _currentIndex = 0;
  List<GlobalKey<ContentScreenState>> _contentScreenKeys = [];

  @override
  void initState() {
    super.initState();
    fetchVideos();
    _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
      fetchVideos();
    });
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/files'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          videos = jsonResponse;
          _contentScreenKeys = List.generate(
            videos.length,
            (_) => GlobalKey<ContentScreenState>(),
          );
          isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() {
      isLoading = false;
    });
  }

  void _onIndexChanged(int index) {
    if (_currentIndex != index) {
      if (_currentIndex < _contentScreenKeys.length) {
        _contentScreenKeys[_currentIndex].currentState?.pauseVideo();
      }
      if (index < _contentScreenKeys.length) {
        _contentScreenKeys[index].currentState?.playVideo();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = index;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            return Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight,
                  child: isLoading
                      ? Center(
                          child: Lottie.asset(
                            'assets/Animated/loading.json',
                            width: 150,
                            height: 150,
                          ),
                        )
                      : Swiper(
                          itemBuilder: (BuildContext context, int index) {
                            return ContentScreen(
                              key: _contentScreenKeys[index],
                              src: videos[index]['url'],
                              userInfo: videos[index]['user_info'],
                              views: videos[index]['views'],
                              reactions: videos[index]['reactions'],
                              shares: videos[index]['shares'],
                              FileID: videos[index]['file_id'],
                              onVisibilityChanged: (visible) {
                                if (visible) {
                                  _onIndexChanged(index);
                                }
                              },
                            );
                          },
                          itemCount: videos.length,
                          scrollDirection: Axis.vertical,
                          onIndexChanged: _onIndexChanged,
                        ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      width: 2,
      height: 20,
      color: Colors.white,
    );
  }
}
