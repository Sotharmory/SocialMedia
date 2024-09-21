import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class UserInfoProvider with ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:5000"; // Your API base URL

  String? _profilePictureUrl;

  String? get profilePictureUrl => _profilePictureUrl;


  Future<Map<String, dynamic>?> getUserInfoById(int userId) async {
    final response = await http.get(Uri.parse('${baseUrl}/user-by-id/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  Future<void> fetchAndUpdateUserInfo(String email) async {
    final userInfo = await getUserInfo(email);
    if (userInfo != null) {
      _profilePictureUrl = userInfo['profile_picture_url'];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getUserInfo(String email) async {
    final url = Uri.parse('$baseUrl/user/${Uri.encodeComponent(email)}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the user info as a Map
      } else {
        print('Failed to retrieve user info: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Error occurred while retrieving user info: $error');
      return null;
    }
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    print('Email saved: $email');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email'); // Returns null if no email is found
  }

  Future<void> saveUserID(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    print('User ID saved: $userId');
  }

  Future<int?> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id'); // Returns null if no user ID is found
  }

  Future<void> removeUserID() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<void> unSaveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }
}