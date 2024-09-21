import 'package:flutter/material.dart';

class Utils {
  static Container socialIcon(String image) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Image.asset(
        image,
        height: 35,
      ),
    );
  }

  static Container myTextField(
      String hint,
      Color color,
      IconData suffixIcon,
      bool isPassword,
      TextEditingController controller, [
        VoidCallback? onSuffixIconPressed,
      ]) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 10,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(15),
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black45,
            fontSize: 19,
          ),
          suffixIcon: onSuffixIconPressed != null
              ? IconButton(
            icon: Icon(
              suffixIcon,
              color: color,
            ),
            onPressed: onSuffixIconPressed, // Use the callback here
          )
              : Icon(
            suffixIcon,
            color: color,
          ),
        ),
      ),
    );
  }
}