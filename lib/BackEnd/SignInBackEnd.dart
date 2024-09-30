import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
// Secure storage
import 'package:Doune/Models/Users.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacebookAuthService {
  Future<void> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        print('User Data: $userData');
        // Handle user data and proceed with your app logic
      } else {
        print('Login failed: ${result.message}');
      }
    } catch (e) {
      print('Error during Facebook login: $e');
    }
  }

  Future<void> logoutFromFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      print('Logged out from Facebook');
    } catch (e) {
      print('Error during Facebook logout: $e');
    }
  }
}

class SignInBackEnd with ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:5000"; // API base URL

  Future<bool> signIn(String email, String password) async {
    final url = Uri.parse('$baseUrl/signin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'Email': email, 'Password': password}),
      );

      if (response.statusCode == 200) {
        var userData = jsonDecode(response.body);
        print('User signed in successfully: $userData');

        // Example of using Users.fromJson to deserialize the response
        Users user = Users.fromJson(userData);


        return true;
      } else {
        print('Failed to sign in: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during sign in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isSignedIn');
    await prefs.remove('userData');
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isSignedIn') ?? false;
  }

  Future<Users?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      return Users.fromJson(jsonDecode(userData));
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Add more email validation if needed
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // Add more password validation if needed
    return null;
  }
}
