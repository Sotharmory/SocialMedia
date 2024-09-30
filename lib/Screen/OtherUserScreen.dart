import 'dart:convert';

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/BackEnd/VideoAPIHandle.dart';
import 'package:Doune/Screen/SettingScreen.dart';
import 'package:Doune/Screen/NotFoundUserScreen.dart';
import 'package:Doune/Screen/StoryPlayerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Doune/Widget/TractSheet.dart';

class OtherUserScreen extends StatefulWidget {
  final int UserId;
  const OtherUserScreen({Key? key, required this.UserId}) : super(key: key);

  @override
  _OtherUserScreenState createState() => _OtherUserScreenState();
}

class _OtherUserScreenState extends State<OtherUserScreen> {
  final userInfoProvider = UserInfoProvider();
  final userVideoList = UserVideoList();

  String? fullName;
  String? bio;
  String? userName;
  int? follower;
  int? point;
  int? following;
  String? profilePictureUrl;
  int? userId;
  bool _isFollowing = false;
  bool? Verified;
  String _selectedTab = "Featured"; // Track selected tab

  @override
  void initState() {
    super.initState();
    _checkIfUserBlocked();
  }

  Future<void> _checkIfUserBlocked() async {
    // Call the async function and wait for the result
    bool blocked = await isUserBlocked();

    if (blocked) {
      // Navigate to NotFoundUserScreen if blocked
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => NotFoundUserScreen()),
      );
    } else {
      // If not blocked, fetch user info
      _fetchUserInfo();
    }
  }

  Future<bool> isUserBlocked() async {
    final String baseUrl = 'http://10.0.2.2:5000';
    final currentUserId =
        await UserInfoProvider().getUserID(); // Ensure this is awaited

    // Kiểm tra xem currentUserId có null hay không
    if (currentUserId == null) {
      return false; // Nếu chưa đăng nhập, trả về false
    }

    // Yêu cầu đầu tiên
    final response = await http.get(
        Uri.parse('$baseUrl/check_blocked/$currentUserId/${widget.UserId}'));

    // Yêu cầu thứ hai
    final responseOther = await http.get(
        Uri.parse('$baseUrl/check_blocked/${widget.UserId}/$currentUserId'));

    // Kiểm tra phản hồi
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print('Check Blocked Response: $data'); // In phản hồi
      return data['is_blocked'] == true; // Trả về true nếu bị chặn
    } else if (responseOther.statusCode == 200) {
      final Map<String, dynamic> dataOther = json.decode(responseOther.body);
      print('Check Blocked Response (other): $dataOther'); // In phản hồi khác
      return dataOther['is_blocked'] == true; // Trả về true nếu bị chặn
    } else {
      throw Exception('Failed to check if user is blocked');
    }
  }

  void _showLottieAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierColor:
              Colors.transparent, // Removes the dark background overlay
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent, // Keep dialog transparent
              child: Center(
                child: Lottie.network(
                  'https://lottie.host/3bf5c985-202d-4a26-b252-52835ae19720/fL0gmM53Ad.json',
                  repeat: false,
                  onLoaded: (composition) {
                    Future.delayed(composition.duration, () {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context)
                            .pop(); // Close the dialog after animation
                      }
                    });
                  },
                ),
              ),
            );
          },
        );
      }
    });
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      double value = number / 1000000000;
      return value.toStringAsFixed(value < 10 ? 1 : 0) + 'T';
    } else if (number >= 1000000) {
      double value = number / 1000000;
      return value.toStringAsFixed(value < 10 ? 1 : 0) + 'M';
    } else if (number >= 1000) {
      double value = number / 1000;
      return value.toStringAsFixed(value < 10 ? 1 : 0) + 'K';
    } else {
      return number.toString();
    }
  }

  Future<bool> _checkIfFollowing(int followedUserId) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final signedUserID = sharedPreferences.getInt('user_id');
    if (signedUserID == null) {
      return false;
    }

    final url = 'http://10.0.2.2:5000/check';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'follower_id': signedUserID,
        'followed_user_id': followedUserId,
      }),
    );
    print('check if follow $signedUserID');
    print('check if follow $followedUserId');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['isFollowing'] ?? false;
    } else {
      throw Exception('Failed to check follow status');
    }
  }

  Future<void> _followUser() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final signedUserID = sharedPreferences.getInt('user_id');

    if (signedUserID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to sign in to follow this user.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'http://10.0.2.2:5000/follow';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'follower_id': signedUserID,
          'followed_id': widget.UserId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _isFollowing = true;
          follower = (follower ?? 0) + 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully followed user.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are already following this user.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow user.'),
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

  Future<void> _unfollowUser() async {
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
          'followed_id': widget.UserId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFollowing = false;
          follower = (follower ?? 0) - 1;
        });
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

  Future<void> _fetchUserInfo() async {
    final url = 'http://10.0.2.2:5000/user-by-id/${widget.UserId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final userInfo = json.decode(response.body);

      // Check if the required fields are present
      if (userInfo is Map<String, dynamic>) {
        // Check if the user is banned
        if (userInfo['isBanned'] == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => NotFoundUserScreen()),
          );
          return; // Exit the method
        }

        setState(() {
          // Safe type conversion
          fullName = userInfo['FullName']?.toString() ?? 'No full name';
          bio = userInfo['Bio']?.toString() ?? 'No bio yet!';
          userName = userInfo['Username']?.toString() ?? 'No username';

          // Try to parse integer values with default fallback
          follower = int.tryParse(userInfo['Follower']?.toString() ?? '') ?? 0;
          point = int.tryParse(userInfo['Point']?.toString() ?? '') ?? 0;
          userId = int.tryParse(userInfo['UserID']?.toString() ?? '');
          following =
              int.tryParse(userInfo['Following']?.toString() ?? '') ?? 0;

          // Safe boolean conversion
          Verified = userInfo['Verified'] is bool
              ? userInfo['Verified'] as bool
              : userInfo['Verified'] == 1;

          // Safe URL conversion
          profilePictureUrl = userInfo['ProfilePictureURL']?.toString() ?? '';
          profilePictureUrl =
              "http://10.0.2.2:5000/download/avatar/$profilePictureUrl";
        });

        if (Verified == true) {
          _showLottieAnimation();
        }

        if (userId != null) {
          final isFollowing = await _checkIfFollowing(userId!);
          setState(() {
            _isFollowing = isFollowing;
          });
          print('isfollow:? $isFollowing');
        }
      } else {
        // Handle unexpected data format
        setState(() {
          fullName = 'Invalid data format';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid data format received from the server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle non-200 status codes
      setState(() {
        fullName = 'Error loading user info';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user info: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 24,
            color: Colors.black,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullName ?? 'Loading...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (Verified == true ||
                Verified == 1) // Check if Verified is true or 1
              const SizedBox(width: 8), // Space between name and icon
            if (Verified == true ||
                Verified == 1) // Check if Verified is true or 1

              Tooltip(
                message:
                    'User ${fullName} is verified by Doune', // Tooltip message
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            'Doune verification',
                            style: TextStyle(
                                color: Colors.blue), // Blue color for title
                          ),
                          content: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Accounts with a verified badge\nhave been verified by ',
                                  style: TextStyle(
                                      color: Colors.black), // Default color
                                ),
                                TextSpan(
                                  text: 'Doune',
                                  style: TextStyle(
                                      color: Colors
                                          .blue), // Blue color for "Doune"
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .end, // Căn chỉnh nội dung về bên phải
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.blue, // Màu chữ
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8), // Bo góc
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8), // Padding của button
                                    elevation: 5, // Độ cao đổ bóng
                                  ),
                                  child: Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blue, // Color of the tick icon
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 24,
              color: Colors.black,
            ),
            onPressed: () {
              // Show TractSheet as a bottom sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return TractSheet(
                    userId: widget.UserId,
                  );
                },
              );
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUserInfo,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(),
                  const SizedBox(height: 24),
                  _buildButtonAction(),
                  const SizedBox(height: 30),
                  _buildTabBar(),
                  const SizedBox(height: 24),
                  _buildGridList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageProfile(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 35),
              _buildDescription(),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: Text(
                  bio ?? 'No bio yet!',
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _buildDescription() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(_formatNumber(following ?? 0), 'Following'),
        _buildStatItem(_formatNumber(follower ?? 0), 'Followers'),
        _buildStatItem(_formatNumber(point ?? 0), 'Touch'),
      ],
    );
  }

  Column _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Stack _buildImageProfile() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // Khi nhấn vào avatar, hiển thị ảnh trong dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    bool isDialogVisible = true;

                    return Dialog(
                      insetPadding: EdgeInsets.all(
                          20), // Adjust padding to add space around the image
                      child: Stack(
                        children: [
                          AnimatedOpacity(
                            opacity: isDialogVisible ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Center(
                              child: ClipOval(
                                child: SizedBox(
                                    width: 400, // Set the desired width
                                    height: 400, // Set the desired height
                                    child: Image.network(
                                      profilePictureUrl!,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.network(
                                            'https://via.placeholder.com/150'); // Fallback image
                                      },
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    )),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.black),
                              onPressed: () {
                                setState(() {
                                  isDialogVisible = false;
                                });
                                Future.delayed(Duration(milliseconds: 300), () {
                                  Navigator.of(context).pop();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          child: Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(65), // Ensures the image is round
              child: profilePictureUrl != null
                  ? Image.network(
                      profilePictureUrl!,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network('https://via.placeholder.com/150');
                      },
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Image.network('https://via.placeholder.com/150'),
            ),
          ),
        ),
      ],
    );
  }

  Row _buildButtonAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(0), // Padding inside the circle
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
            tooltip: 'Message',
            iconSize: 30, // Adjust icon size if needed
          ),
        ),
        SizedBox(
          width: 10,
        ),
        ElevatedButton(
          onPressed: () {
            if (_isFollowing) {
              _unfollowUser();
            } else {
              _followUser();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlueAccent,
            minimumSize: const Size(120, 45),
            elevation: 8,
            shadowColor: Colors.green.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            final textToCopy = userName != null ? '@$userName' : 'Loading...';
            Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$textToCopy copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(120, 45),
            elevation: 8,
            shadowColor: Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            userName != null ? '@$userName' : 'Loading...',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Row _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = "Featured";
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedTab == "Featured"
                      ? Colors.redAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              "Featured",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _selectedTab == "Featured"
                    ? Colors.lightBlueAccent
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = "Story";
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedTab == "Story"
                      ? Colors.redAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              "Story",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _selectedTab == "Story"
                    ? Colors.lightBlueAccent
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = "Tagged";
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedTab == "Tagged"
                      ? Colors.redAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              "Tagged",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _selectedTab == "Tagged"
                    ? Colors.lightBlueAccent
                    : Colors.grey,
              ),
            ),
          ),
        ),
        Spacer(),
        Icon(Icons.more_horiz, color: Colors.black),
      ],
    );
  }

  Widget _buildGridList() {
    if (userId == null) {
      return Center(
        child: Lottie.asset(
          'assets/Animated/loading.json', // Path to your no data animation
          width: 150,
          height: 150,
        ),
      );
    }

    Future<List<FileItem>> futureVideos;
    if (_selectedTab == "Featured") {
      futureVideos = userVideoList.fetchUserVideoFeatured(userId!);
    } else {
      futureVideos = userVideoList.fetchUserVideos(userId!);
    }

    return FutureBuilder<List<FileItem>>(
      future: futureVideos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              'assets/Animated/loading.json',
              width: 150,
              height: 150,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text(
            'No video available',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ));
        } else {
          final videos = snapshot.data!;
          return SizedBox(
            height: 600,
            width: double.infinity,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.62,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDisplayScreen(
                          videos: videos,
                          initialIndex: index,
                          user: false,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: video.type == 'video'
                                ? Colors.lightBlueAccent
                                : Colors.redAccent,
                            width: 3.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: video.type == 'video'
                                ? Image.network(
                                    video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading thumbnail: $error');
                                      return Image.network(
                                        'https://example.com/placeholder.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.network(
                                    video.url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Image.network(
                                        'https://example.com/placeholder.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${video.views}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // Add more options here
            ],
          ),
        );
      },
    );
  }
}
