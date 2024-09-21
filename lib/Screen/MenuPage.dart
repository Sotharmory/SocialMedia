import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Doune/Screen/AuthScreen.dart';
import 'package:Doune/Screen/CameraScreen.dart';
import 'package:Doune/Screen/HomeScreen.dart';
import 'package:Doune/Screen/MessageScreen.dart';
import 'package:Doune/Screen/SearchScreen.dart';
import 'package:Doune/Screen/UserScreen.dart';

class HomePage extends StatefulWidget {
  final bool isSignedIn;
  const HomePage({required this.isSignedIn, Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Widget _buildScreen(int index) {
    if (widget.isSignedIn) {
      switch (index) {
        case 0:
          return HomeScreen();
        case 1:
          return SearchScreen(isSignedIn: widget.isSignedIn);
        case 2:
          return _buildLazyCameraScreen();
        case 3:
          return Messages();
        case 4:
          return UserScreen();
        default:
          return Container();
      }
    } else {
      switch (index) {
        case 0:
          return HomeScreen();
        case 1:
          return SearchScreen(isSignedIn: widget.isSignedIn);
        case 2:
          return _buildLazyCameraScreen();
        case 3:
        case 4:
          return AuthmeScreen();
        default:
          return Container();
      }
    }
  }

  Widget _buildLazyCameraScreen() {
    return FutureBuilder<bool>(
      future: _checkAndRequestCameraPermission(),
      builder: (context, permissionSnapshot) {
        if (permissionSnapshot.connectionState == ConnectionState.done) {
          if (permissionSnapshot.data == true) {
            return FutureBuilder<List<CameraDescription>>(
              future: availableCameras(),
              builder: (context, cameraSnapshot) {
                if (cameraSnapshot.connectionState == ConnectionState.done) {
                  if (cameraSnapshot.hasData) {
                    return CameraScreen(cameras: cameraSnapshot.data!);
                  } else {
                    return Center(child: Text('Không thể truy cập camera'));
                  }
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return Center(child: Text('Quyền truy cập camera bị từ chối'));
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(currentIndex),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: Colors.lightBlueAccent, size: 30),
              selectedIcon: Icon(Icons.home, color: Colors.redAccent, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined,
                  color: Colors.lightBlueAccent, size: 30),
              selectedIcon:
                  Icon(Icons.search, color: Colors.redAccent, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon:
                  Icon(Icons.telegram, color: Colors.lightBlueAccent, size: 30),
              selectedIcon: Icon(Icons.telegram_outlined,
                  color: Colors.redAccent, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined,
                  color: Colors.lightBlueAccent, size: 30),
              selectedIcon: Icon(Icons.chat, color: Colors.redAccent, size: 30),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: Colors.lightBlueAccent, size: 30),
              selectedIcon:
                  Icon(Icons.person, color: Colors.redAccent, size: 30),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
