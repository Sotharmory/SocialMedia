import 'package:Doune/Widget/BioEditor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Widget/FullNameEditor.dart';
import 'package:intl/intl.dart';
import 'package:Doune/Widget/UserIDEditor.dart';

String formatDate(String dateString) {
  if (dateString.isEmpty)
    return 'There are no updated'; // Kiểm tra trước khi parse
  try {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  } catch (e) {
    print('Lỗi định dạng ngày: $e'); // In lỗi ra console
    return 'Không hợp lệ'; // Giá trị mặc định nếu lỗi
  }
}

const double tDefaultSize = 16.0;
const double tFormHeight = 50.0;
const Color tPrimaryColor = Colors.blue;
const Color tDarkColor = Colors.white;

const String tEditProfile = 'Share your profile';
const String tFullName = 'Full Name';
const String tUserId = 'Doune ID';
const String tBio = 'Bio';
const String tProfileImage = 'assets/DefaultAvatar/defaultavt.jpg';

class ProfileController extends GetxController {}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String fullName = '';
  String bio = '';
  int? userId;
  String profilePictureUrl = tProfileImage; // Default image
  String userName = '';
  bool? verified;
  String updatedAt = '';
  String updatedAtUsername = '';

  final userInfoProvider = UserInfoProvider();

  @override
  void initState() {
    _fetchUsername();
    super.initState();
  }

  Future<void> _fetchUsername() async {
    final id = await userInfoProvider.getUserID();
    if (id != null) {
      final userInfo = await userInfoProvider.getUserInfoById(id);
      print("fetch data: $userInfo");
      if (userInfo != null) {
        setState(() {
          fullName = userInfo['FullName'];
          bio = userInfo['Bio'];
          userId = id;
          userName = userInfo['Username'];
          profilePictureUrl =
              "http://10.0.2.2:5000/download/avatar/${userInfo['ProfilePictureURL']}";
          verified = userInfo['Verified'];
          updatedAt = formatDate(userInfo['UpdatedAt']);
          updatedAtUsername = formatDate(userInfo['UpdatedAtUsername']);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(tDefaultSize),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                          profilePictureUrl), // Use network image for profile picture
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.blue, // You can customize this
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white), // Edit icon
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // -- Name Display
              GestureDetector(
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullNameEditorSheet(
                          fullName: fullName,
                          userId: userId!,
                          updateAt: updatedAt,
                        ), // Pass the current full name
                      ),
                    ).then((newFullName) {
                      if (newFullName != null && newFullName is String) {
                        setState(() {
                          fullName =
                              newFullName; // Update the full name state if needed
                        });
                      }
                    });
                  } else {
                    // Handle the case where userId is null (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not found')),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tFullName,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(fullName, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.lightBlueAccent),
                  ],
                ),
              ),
              const SizedBox(height: tFormHeight - 20),

              // -- User ID Display
              GestureDetector(
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserIdEditorSheet(
                          userName: userName,
                          userId: userId!,
                          updateAt: updatedAtUsername,
                        ), // Pass the current full name
                      ),
                    ).then((newUserName) {
                      if (newUserName != null && newUserName is String) {
                        setState(() {
                          userName =
                              newUserName; // Corrected from newFullName to newUserName
                        });
                      }
                    });
                  } else {
                    // Handle the case where userId is null (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not found')),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(tUserId,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(userName, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.lightBlueAccent),
                  ],
                ),
              ),
              const SizedBox(height: tFormHeight - 20),

              // -- Bio Display
              GestureDetector(
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BioEditorSheet(
                          bio: bio,
                          userId: userId!,
                        ), // Pass the current full name
                      ),
                    ).then((newBio) {
                      if (newBio != null && newBio is String) {
                        setState(() {
                          bio =
                              newBio; // Corrected from newFullName to newUserName
                        });
                      }
                    });
                  } else {
                    // Handle the case where userId is null (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not found')),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(tBio,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(bio.isNotEmpty ? bio : 'No bio yet!',
                        style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.lightBlueAccent),
                  ],
                ),
              ),
              const SizedBox(height: tFormHeight - 20),

              // -- Form Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add your update profile logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tPrimaryColor,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(tEditProfile,
                      style: TextStyle(color: tDarkColor)),
                ),
              ),
              const SizedBox(height: tFormHeight),

              // -- Created Date and Delete Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add other UI elements as needed
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
