import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Doune/Models/Users.dart'; // Adjust according to your project


class SignUpBackEnd with ChangeNotifier {
  final String baseUrl = "http://10.0.2.2:5000"; // Ensure this URL is correct

  Future<bool> signUp(String email, String password,
      DateTime dateOfBirth) async {
    final url = Uri.parse('$baseUrl/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
          'DateOfBirth': DateFormat("yyyy-MM-dd").format(dateOfBirth),
          // Convert DateTime to string
        }),
      );

      if (response.statusCode == 201) {
        var userData = jsonDecode(response.body);
        print('User signed up successfully: $userData');

        // Use Users.fromJson to deserialize the response
        Users user = Users.fromJson(userData);
        print('User object: $user');

        return true;
      } else {
        print('Failed to sign up: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during sign up: $e');
      return false;
    }
  }

  Future<String?> checkEmailExists(String email) async {
    final url = Uri.parse('$baseUrl/checkemail');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      print('Response status: ${response.statusCode}'); // Log response status
      print('Response body: ${response.body}'); // Log response body

      if (response.statusCode == 200) {
        final emailCheckResponse = jsonDecode(response.body);
        final bool emailExists = emailCheckResponse['exists'];
        return emailExists ? 'The email is already registered' : null;
      } else {
        print('Failed to check email: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during email validation: $e');
    }
    return null;
  }


  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  Future<String?> validateEmailAsync(String? value) async {
    String? syncValidationResult = validateEmail(value);
    if (syncValidationResult != null) {
      return syncValidationResult;
    }
    return await checkEmailExists(value!);
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // Add any additional password validation logic here
    return null;
  }

  String? validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return "Please select your date of birth";
    }

    DateTime? selectedDate;
    List<String> formats = ["dd-MM-yyyy", "yyyy-MM-dd"]; // Add more formats if needed

    for (String format in formats) {
      try {
        selectedDate = DateFormat(format).parseStrict(value);
        print("Parsed Date with format $format: $selectedDate");
        break; // Exit loop if parsing is successful
      } catch (e) {
        print("Error with format $format: $e");
      }
    }

    if (selectedDate == null) {
      return "Invalid date format. Use dd-MM-yyyy or yyyy-MM-dd.";
    }

    // Calculate age
    DateTime today = DateTime.now();
    int age = today.year - selectedDate.year;

    // Adjust age if the birthdate has not yet occurred this year
    if (today.month < selectedDate.month ||
        (today.month == selectedDate.month && today.day < selectedDate.day)) {
      age--;
    }
    print("Calculated Age: $age");

    // Check if age is less than 18
    if (age < 18) {
      return "You must be at least 18 years old.";
    }

    return null; // No validation error
  }
}
