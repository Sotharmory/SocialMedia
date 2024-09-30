import 'dart:convert';
import 'package:http/http.dart' as http;

// UserInfo class for storing user information
class UserInfo {
  final int userId;
  final String email;
  final String fullName;
  final String username;
  final String profilePicture;
  final bool verified; // New field for verified status

  UserInfo({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.username,
    required this.profilePicture,
    required this.verified, // Initialize new field
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    print('UserInfo JSON: $json'); // Debugging output
    return UserInfo(
      userId: json['UserID'] ?? 0,
      email: json['Email'] ?? '',
      fullName: json['FullName'] ?? '',
      username: json['Username'] ?? '',
      profilePicture: json['ProfilePicture'] ?? '',
      verified: json['Verified'] ?? false, // Parse verified status
    );
  }
}

// FileItem class for storing file details
class FileItem {
  final String fileId;
  final String filename;
  final int reactions;
  final int shares;
  final String status;
  final String type;
  final String url;
  final String thumbnailUrl;
  final int views;
  final String thumbnailId;
  final bool featured;
  final bool private; // New field for private status

  FileItem({
    required this.fileId,
    required this.filename,
    required this.reactions,
    required this.shares,
    required this.status,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    required this.views,
    required this.thumbnailId,
    required this.featured,
    required this.private, // Initialize new field
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    print('FileItem JSON: $json'); // Debugging output

    final thumbnailUrl = json['thumbnail_url'] ??
        'https://example.com/placeholder.png'; // Default placeholder URL
    print('Thumbnail URL: $thumbnailUrl'); // Print thumbnail URL

    final metadata = json['metadata'] ?? {}; // Ensure metadata is not null
    final thumbnailId = metadata['thumbnail_id'] ?? ''; // Parse thumbnail ID

    return FileItem(
      fileId: json['file_id'],
      filename: json['filename'],
      reactions: json['reactions'] ?? 0,
      shares: json['shares'] ?? 0,
      status: json['status'],
      type: json['type'],
      url: json['url'],
      thumbnailUrl: thumbnailUrl,
      views: json['views'] ?? 0,
      thumbnailId: thumbnailId,
      featured: json['featured'] ?? false,
      private: json['private'] ?? false, // Parse private status
    );
  }
}

// Class to handle API requests related to user videos
class UserVideoList {
  final String baseUrl = 'http://10.0.2.2:5000'; // Update with your server URL

  Future<List<FileItem>> fetchUserVideos(int userId) async {
    final url = '$baseUrl/user-videos?user_ids=$userId&include_thumbnails=true';
    print('Fetching user videos from URL: $url'); // Debugging output

    try {
      final response = await http.get(Uri.parse(url));
      _checkResponse(response);

      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map<FileItem>((video) => FileItem.fromJson(video)).toList();
    } catch (e) {
      print('Error fetching user videos: $e');
      return [];
    }
  }

  Future<List<FileItem>> VideoFeatured(int userId) async {
    final url = '$baseUrl/videofeatured?user_id=$userId';
    print('Fetching featured user videos from URL: $url'); // Debugging output

    try {
      final response = await http.get(Uri.parse(url));
      _checkResponse(response);

      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map<FileItem>((video) => FileItem.fromJson(video)).toList();
    } catch (e) {
      print('Error fetching featured user videos: $e');
      return [];
    }
  }

  Future<List<FileItem>> fetchUserVideoFeatured(int userId) async {
    final url = '$baseUrl/getuservideofeatured?user_id=$userId';
    print('Fetching featured user videos from URL: $url'); // Debugging output

    try {
      final response = await http.get(Uri.parse(url));
      _checkResponse(response);

      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map<FileItem>((video) => FileItem.fromJson(video)).toList();
    } catch (e) {
      print('Error fetching featured user videos: $e');
      return [];
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      print('Failed to load: ${response.body}'); // Print response body on error
      throw Exception('Failed with status code ${response.statusCode}');
    }
  }
}

// Class to handle API requests related to files
class VideoAPIHandle {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<List<FileItem>> fetchFiles(int offset, int limit) async {
    final url = '$baseUrl/files?offset=$offset&limit=$limit';
    print('Fetching files from URL: $url'); // Debugging output

    try {
      final response = await http.get(Uri.parse(url));
      _checkResponse(response);

      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map<FileItem>((json) => FileItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching files: $e');
      return [];
    }
  }

  Future<void> incrementViewCount(String fileId) async {
    final url = '$baseUrl/video/$fileId/view';
    print('Incrementing view count for file ID: $fileId'); // Debugging output

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fileId': fileId}),
      );

      if (response.statusCode != 200) {
        print(
            'Failed to update view count: ${response.body}'); // Debugging output
        throw Exception(
            'Failed to update view count with status code ${response.statusCode}');
      }
      print('View count updated successfully for file $fileId.');
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      print('Failed to load: ${response.body}'); // Print response body on error
      throw Exception('Failed with status code ${response.statusCode}');
    }
  }
}
