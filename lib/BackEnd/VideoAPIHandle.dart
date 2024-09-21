import 'dart:convert';
import 'package:http/http.dart' as http;

// UserInfo class for storing user information
class UserInfo {
  final int userId;
  final String email;
  final String fullName;
  final String username;
  final String profilePicture;

  UserInfo({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.username,
    required this.profilePicture,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['UserID'] ?? 0,
      email: json['Email'] ?? '',
      fullName: json['FullName'] ?? '',
      username: json['Username'] ?? '',
      profilePicture: json['ProfilePicture'] ?? '',
    );
  }
}

// FileItem class for storing file details
class FileItem {
  final String fileId;
  final String filename;
  final String url;
  final String type;
  final UserInfo userInfo;
  final int views;
  final int reactions;
  final int shares;

  FileItem({
    required this.fileId,
    required this.filename,
    required this.url,
    required this.type,
    required this.userInfo,
    required this.views,
    required this.reactions,
    required this.shares,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['file_id'] ?? '',
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'unknown',
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
      views: json['views'] ?? 0,
      reactions: json['reactions'] ?? 0,
      shares: json['shares'] ?? 0,
    );
  }
}

// Class to handle API requests related to user videos
class UserVideoList {
  final String baseUrl = 'http://10.0.2.2:5000'; // Update with your server URL

  Future<List<FileItem>> fetchUserVideos(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user-videos?user_ids=$userId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      print('Raw JSON data: $data'); // Print the raw JSON data

      return data.map((video) {
        if (video == null || video is! Map<String, dynamic>) {
          print('Error: video item is null or not a Map');
          return FileItem(
            fileId: '',
            filename: '',
            url: '',
            type: 'unknown',
            userInfo: UserInfo(
              userId: 0,
              email: '',
              fullName: '',
              username: '',
              profilePicture: '',
            ),
            views: 0,
            reactions: 0,
            shares: 0,
          );
        }

        try {
          return FileItem.fromJson(video);
        } catch (e) {
          print('Error parsing video item: $e');
          return FileItem(
            fileId: '',
            filename: '',
            url: '',
            type: 'unknown',
            userInfo: UserInfo(
              userId: 0,
              email: '',
              fullName: '',
              username: '',
              profilePicture: '',
            ),
            views: 0,
            reactions: 0,
            shares: 0,
          );
        }
      }).toList();
    } else {
      throw Exception('Failed to load videos with status code ${response.statusCode}');
    }
  }
}

// Class to handle API requests related to files
class VideoAPIHandle {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<List<FileItem>> fetchFiles(int offset, int limit) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/files?offset=$offset&limit=$limit'));

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ?? false) {
          List<dynamic> data = json.decode(response.body) as List<dynamic>;
          List<FileItem> fileItems = [];
          Set<String> processedFileIds = {}; // Track processed file IDs

          for (var json in data) {
            try {
              FileItem fileItem = FileItem.fromJson(json as Map<String, dynamic>);
              fileItems.add(fileItem);

              // Increment the view count if not already processed
              if (!processedFileIds.contains(fileItem.fileId)) {
                processedFileIds.add(fileItem.fileId);
              }

            } catch (e) {
              print('Error parsing file item: $e');
              fileItems.add(FileItem(
                fileId: '',
                filename: '',
                url: '',
                type: 'unknown',
                userInfo: UserInfo(
                  userId: 0,
                  email: '',
                  fullName: '',
                  username: '',
                  profilePicture: '',
                ),
                views: 0,
                reactions: 0,
                shares: 0,
              ));
            }
          }

          return fileItems;
        } else {
          throw Exception('Unexpected content type: ${response.headers['content-type']}');
        }
      } else {
        throw Exception('Failed to load files with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<void> incrementViewCount(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/video/$fileId/view'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fileId': fileId}), // Sending fileId in the body for reference
      );

      if (response.statusCode == 200) {
        print('View count updated successfully for file $fileId.');
      } else {
        throw Exception('Failed to update view count for file $fileId with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
