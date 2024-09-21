import 'package:flutter/material.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});
//Find all video and user if start with keyword
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.grey,
      ),
      backgroundColor: Colors.white,
      body: Scaffold(
        body: Column(
          children: [

          ],
        ),
      )
    );
  }
}