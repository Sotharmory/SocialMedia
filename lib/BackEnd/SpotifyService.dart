import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  final String _clientId = 'd9ef0d4544444ed0b856076eda7ffb7d';
  final String _clientSecret = 'cb30b4182d1b413b896bf8f4e36ae604';
  String? _accessToken;

  Future<void> authenticate() async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$_clientId:$_clientSecret')),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
    } else {
      throw Exception('Failed to authenticate');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategorySongs(String category) async {
    if (_accessToken == null) {
      await authenticate();
    }

    String url;
    switch (category) {
      case 'Hot Hit':
        url = 'https://api.spotify.com/v1/browse/categories/toplists/playlists'; // Playlist hot hit
        break;
      case 'Trending':
        url = 'https://api.spotify.com/v1/browse/categories/genre-playlists/playlists'; // Playlist xu hướng
        break;
      case 'New':
        url = 'https://api.spotify.com/v1/browse/new-releases'; // Các phát hành mới
        break;
      default:
        throw Exception('Unknown category');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_accessToken!',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> items;

      if (category == 'New') {
        items = (data['albums']['items'] as List<dynamic>).map((item) {
          final album = item as Map<String, dynamic>;
          final images = (album['images'] as List<dynamic>?) ?? [];
          final imageUrl = images.isNotEmpty ? images[0]['url'] : '';
          return {
            'name': album['name'],
            'image': imageUrl,
            'previewUrl': '', // Không phải lúc nào cũng có previewUrl
            'duration': '0:00', // Thời gian bài hát không có trong API phát hành mới
          };
        }).toList();
      } else {
        // Lấy các playlist từ danh mục
        final playlists = (data['playlists']['items'] as List<dynamic>);
        items = [];

        for (var playlist in playlists) {
          final playlistId = playlist['id'];
          final playlistUrl = 'https://api.spotify.com/v1/playlists/$playlistId/tracks';
          final playlistResponse = await http.get(
            Uri.parse(playlistUrl),
            headers: {
              'Authorization': 'Bearer $_accessToken!',
            },
          );

          if (playlistResponse.statusCode == 200) {
            final playlistData = json.decode(playlistResponse.body);
            final tracks = (playlistData['items'] as List<dynamic>).map((trackItem) {
              final track = trackItem['track'] as Map<String, dynamic>;
              final imageUrl = track['album']['images'].isNotEmpty ? track['album']['images'][0]['url'] : '';
              final previewUrl = track['preview_url'] ?? ''; // Preview URL cho bài hát
              final durationMs = track['duration_ms'] ?? 0;
              final duration = _formatDuration(durationMs);
              return {
                'name': track['name'],
                'image': imageUrl,
                'previewUrl': previewUrl,
                'duration': duration, // Thời gian bài hát
              };
            }).toList();

            items.addAll(tracks);
          } else {
            throw Exception('Failed to load playlist tracks');
          }
        }
      }

      return items;
    } else {
      throw Exception('Failed to load songs');
    }
  }

  Future<List<dynamic>> searchSongs(String query) async {
    if (_accessToken == null) {
      await authenticate();
    }

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=$query&type=track'),
      headers: {
        'Authorization': 'Bearer $_accessToken!',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tracks = data['tracks']['items'] as List<dynamic>;

      return tracks.map((track) {
        final album = track['album'] as Map<String, dynamic>;
        final images = (album['images'] as List<dynamic>?) ?? [];
        final imageUrl = images.isNotEmpty ? images[0]['url'] : '';
        print(imageUrl);
        return {
          'name': track['name'],
          'image': imageUrl,
          'previewUrl': track['preview_url'] ?? '',
          'duration': _formatDuration(track['duration_ms'] ?? 0),
        };
      }).toList();
    } else {
      throw Exception('Failed to load songs');
    }
  }


  // Chuyển đổi thời gian từ milliseconds thành định dạng phút:giây
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
