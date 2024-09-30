import 'dart:convert';

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/BackEnd/VideoAPIHandle.dart';
import 'package:Doune/Screen/AvatarView.dart';
import 'package:Doune/Screen/EditProfileScreen.dart';
import 'package:Doune/Screen/SettingScreen.dart';
import 'package:Doune/Screen/StoryPlayerScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:Doune/Widget/FollowListScreen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
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

class _UserScreenState extends State<UserScreen> {
  final userInfoProvider = UserInfoProvider();
  final uservideolist = UserVideoList();
  final AVTVIEW = AvatarView(
    imageUrl: '',
  );
  bool _isUploading = false; // Track upload state

  String? fullName;
  String? bio;
  String? userName;
  int? Follower;
  int? Point;
  int? Following;
  String? profilePictureUrl;
  int? UserId;
  bool? Verified;
  String _selectedTab = "Featured"; // Track selected tab

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final userid = await userInfoProvider.getUserID();
    if (userid != null) {
      final userInfo = await userInfoProvider.getUserInfoById(userid);
      if (userInfo != null) {
        setState(() {
          fullName = userInfo['FullName'];
          bio = userInfo['Bio'];
          userName = userInfo['Username'];
          Follower = userInfo['Follower'];
          Point = userInfo['Point'];
          UserId = userInfo['UserID'];
          Following = userInfo['Following'];
          profilePictureUrl =
              "http://10.0.2.2:5000/download/avatar/${userInfo['ProfilePictureURL']}";
          Verified = userInfo['Verified'];
        });
      }
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
          onPressed: () => {},
          icon: const Icon(
            Icons.monetization_on_sharp,
            size: 24,
            color: Colors.yellow,
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
                    'This is a verification badge \nby Doune. This badge will help \nyour account avoid being \ntampered with.', // Tooltip message
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
              // Navigate to EditProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUsername, // Call the method to refresh user info
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(right: 24, left: 24, top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
      children: [
        _buildImageProfile(), // Avatar on the left
        const SizedBox(width: 16), // Space between avatar and text
        Expanded(
          // Allow text to take the remaining space
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the start
            children: [
              SizedBox(
                height: 35,
              ),
              _buildDescription(), // Description below the username
              const SizedBox(
                height: 20,
              ), // Space between description and bio
              Align(
                alignment: Alignment.center, // Align text to the right
                child: Text(
                  bio != null && bio!.isNotEmpty
                      ? bio!
                      : 'No bio yet!', // Check if bio is not null or empty
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

  void _FollowerAlert(BuildContext context, String title, int count) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
              child: Text(
            title,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          )), // Đặt tiêu đề nằm giữa
          content: SizedBox(
            width: double.maxFinite,
            child: FollowListScreen(
              userId: UserId!,
              isFollowers: true,
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Colors.lightBlueAccent, // Thay đổi màu nền của nút
                ),
              ),
            )
          ],
        );
      },
    );
  }

  void _FollowingAlert(BuildContext context, String title, int count) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent), // Tùy chỉnh kiểu chữ tiêu đề
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FollowListScreen(
              userId: UserId!,
              isFollowers: false,
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Colors.lightBlueAccent, // Thay đổi màu nền của nút
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Row _buildDescription() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () => _FollowingAlert(context, "Following", Following ?? 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatNumber(Following ?? 0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Following",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _FollowerAlert(context, "Followers", Follower ?? 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatNumber(Follower ?? 0),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Followers",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _formatNumber(Point ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Touch",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Stack _buildImageProfile() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
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
            borderRadius: BorderRadius.circular(60),
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
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 24),
            onPressed: () => _showEditOptions(context),
          ),
        ),
      ],
    );
  }

  Row _buildButtonAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            // Show EditProfileScreen as a modal bottom sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the bottom sheet
                            },
                          ),
                        ],
                      ),
                      // Content of the EditProfileScreen
                      Expanded(
                        child:
                            EditProfileScreen(), // Ensure it takes up remaining space
                      ),
                    ],
                  ),
                );
              },
            );
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
          child: const Text(
            'Edit Profile',
            style: TextStyle(
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
            backgroundColor: Colors.blueAccent, // Different color
            minimumSize: const Size(120, 45),
            elevation: 8,
            shadowColor: Colors.grey.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            userName != null
                ? '@$userName'
                : 'Loading...', // Display username or loading text
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
              _selectedTab = "Storage Area";
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedTab == "Storage Area"
                      ? Colors.redAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              "Storage Area",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _selectedTab == "Storage Area"
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
              _selectedTab = "Touched";
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _selectedTab == "Touched"
                      ? Colors.redAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              "Touched",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _selectedTab == "Touched"
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
    final userId = UserId;

    if (userId == null) {
      return Center(
        child: Lottie.asset(
          'assets/Animated/loading.json', // Path to your no data animation
          width: 150,
          height: 150,
        ),
      );
    }

    print('Fetching videos for user ID: $userId'); // Debugging output

    Future<List<FileItem>> futureVideos;
    if (_selectedTab == "Featured") {
      futureVideos = uservideolist.VideoFeatured(userId);
    } else {
      futureVideos = uservideolist.fetchUserVideos(userId);
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
              'You don\'t have any story',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
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
                          user: true,
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
                            color: Colors.black.withOpacity(
                                0.6), // Semi-transparent background
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
                                '${video.views}', // Display the number of views
                                style: TextStyle(
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

  Future<void> _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:5000/upload-avatar'),
        );

        // Add the file to the request
        request.files.add(
          kIsWeb
              ? http.MultipartFile.fromBytes(
                  'file',
                  bytes,
                  filename: pickedFile.name,
                )
              : await http.MultipartFile.fromPath(
                  'file',
                  pickedFile.path,
                ),
        );

        // Add the UserID field
        final userid = await userInfoProvider.getUserID();
        if (userid != null) {
          request.fields['user_id'] =
              userid.toString(); // Ensure the field matches API
        } else {
          throw Exception('UserID is null');
        }

        // Send the request
        final response = await request.send();
        final responseData = await response.stream.toBytes();

        if (response.statusCode == 201) {
          final result = json.decode(String.fromCharCodes(responseData));

          setState(() {
            profilePictureUrl =
                result['file_url'] as String; // Update the profile picture URL
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to upload image. Status code: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No image selected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditOptions(BuildContext context) {
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Chụp ảnh'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Tải Ảnh Lên'),
                onTap: () async {
                  await _uploadImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Xem Ảnh'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        insetPadding: EdgeInsets.all(
                            20), // Adjust padding to add space around the image
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 400, // Set the desired width
                                    height: 400, // Set the desired height
                                    child: Image.network(
                                      '$profilePictureUrl', // Use your image URL
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.black),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Hủy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
