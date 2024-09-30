import 'package:Doune/Screen/ChangePassWordWhenSignIn.dart';
import 'package:Doune/Screen/EditProfileScreen.dart';
import 'package:Doune/Screen/PrivacyMode.dart';
import 'package:Doune/SupportCenter/FAQ.dart';
import 'package:Doune/SupportCenter/IdentityVerification.dart';
import 'package:Doune/SupportCenter/SupportRequestForm.dart';
import 'package:flutter/material.dart';
import 'package:Doune/Screen/HomeScreen.dart';
import 'package:Doune/Screen/MenuPage.dart';
import 'package:Doune/Screen/BlockList.dart'; // Màn hình Block List
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/BackEnd/SignInBackEnd.dart';

class SettingScreen extends StatefulWidget {
  SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int? userId;
  SignInBackEnd signinbackend = SignInBackEnd(); // Thêm trường signinbackend

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    final id = await UserInfoProvider().getUserID();
    setState(() {
      userId = id; // Cập nhật state với userId
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Quay lại màn hình trước
          },
        ),
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildListItem(context, 'Edit Profile', EditProfileScreen(), isBottomSheet: true),
            _buildDivider(),
            _buildListItem(context, 'Theme Settings', HomeScreen()),
            _buildDivider(),
            _buildListItem(context, 'Languages', HomeScreen()),
            _buildDivider(),
            _buildListItem(context, 'Notification Settings', HomeScreen()),
            _buildDivider(),
            const SizedBox(height: 20),
            const Text(
              'Privacy & Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildListItem(context, '2-Layer Authentication', null),
            _buildDivider(),
            _buildListItem(context, 'Change Password', ChangePassWordWhenSignIn()),
            _buildDivider(),
            _buildListItem(context, 'Privacy Mode', PrivacyMode()),
            _buildDivider(),
            _buildListItem(context, 'Add an Account Link', null),
            _buildDivider(),
            userId != null
                ? _buildListItem(context, 'List of Blocked Users', BlockList(userId: userId!))
                : Container(), // Kiểm tra userId có khác null hay không
            _buildDivider(),
            const SizedBox(height: 20),
            const Text(
              'Account Support Center',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildListItem(context, 'Doune Policies and Terms', null),
            _buildDivider(),
            _buildListItem(context, 'FAQ', FAQScreen()),
            _buildDivider(),
            _buildListItem(context, 'Identity Verification', IdentityVerification()),
            _buildDivider(),
            _buildListItem(context, 'Request Support', SupportRequestForm()),
            _buildDivider(),
            const SizedBox(height: 20), // Space before Sign Out
            _buildSignOutItem(context), // Sign Out item
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title, Widget? nextPage, {bool isBottomSheet = false}) {
    return GestureDetector(
      onTap: () {
        if (isBottomSheet && title == 'Edit Profile') {
          // Show Edit Profile as a BottomSheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows the BottomSheet to take full height
            builder: (BuildContext context) {
              return Container(
                height: MediaQuery.of(context).size.height * 1, // Set height to 80% of the screen
                child: EditProfileScreen(), // Your EditProfileScreen
              );
            },
          );
        } else if (nextPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextPage),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feature not implemented yet.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildSignOutItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng hộp thoại
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                  ),
                  onPressed: () async {
                    await signinbackend.signOut(); // Gọi phương thức đăng xuất

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomePage(isSignedIn: false)),
                          (route) => false, // Loại bỏ tất cả các màn hình trước đó
                    );
                  },
                  child: Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent, // Background color
          borderRadius: BorderRadius.circular(30), // Rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the Row
          children: [
            Text('Sign Out', style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold)), // Change text color for better contrast
            SizedBox(width: 8), // Space between text and icon
            Icon(Icons.exit_to_app, size: 16, color: Colors.white), // Change icon color for better contrast
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(thickness: 1.0); // Divider line between items
  }
}
