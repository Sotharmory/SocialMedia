import 'package:flutter/material.dart';
import 'package:Doune/BackEnd/SpotifyService.dart'; // Import lớp SpotifyService bạn đã tạo
import 'package:lottie/lottie.dart';

class SoundWidget extends StatefulWidget {
  final Function(Map<String, dynamic>?) onAddSound; // Callback khi thêm hoặc gỡ bài hát
  final Map<String, dynamic>? selectedSound; // Trạng thái bài hát đã chọn

  SoundWidget({Key? key, required this.onAddSound, this.selectedSound}) : super(key: key);

  @override
  _SoundWidgetState createState() => _SoundWidgetState();
}

class _SoundWidgetState extends State<SoundWidget> {
  final SpotifyService _spotifyService = SpotifyService();
  String _selectedCategory = 'Trending';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Hot Hit', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'name': 'Trending', 'icon': Icons.trending_up, 'color': Colors.purple},
    {'name': 'New', 'icon': Icons.new_releases, 'color': Colors.green},
    {'name': 'Save', 'icon': Icons.bookmark, 'color': Colors.blue}
  ];
  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedSong;

  @override
  void initState() {
    super.initState();
    _fetchSongsForCategory(_selectedCategory); // Load dữ liệu cho category mặc định
    _selectedSong = widget.selectedSound; // Gán bài hát đã chọn từ MediaEditor
  }

  Future<void> _fetchSongsForCategory(String category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _spotifyService.fetchCategorySongs(category);
      setState(() {
        _songs = songs.map((song) {
          final imageUrl = song['image'] ?? ''; // Đảm bảo imageUrl không bị null
          final duration = song['duration'] ?? '0:00'; // Lấy thời gian bài hát
          return {
            'name': song['name'] ?? 'No title',
            'image': imageUrl,
            'previewUrl': song['previewUrl'] ?? '', // URL âm thanh xem trước
            'duration': duration // Thêm thời gian bài hát
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching songs for category: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSongs(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final songs = await _spotifyService.searchSongs(query);

      // Debugging: Print the raw response to inspect the data structure
      print('Raw API Response: $songs');

      setState(() {
        _songs = songs.map((song) {
          final imageUrl = song['image'] ?? ''; // Directly use the image URL
          final duration = song['duration'] ?? '0:00'; // Ensure duration is present

          // Debugging: Print image URL for each song
          print('Image URL for ${song['name']}: $imageUrl');

          return {
            'name': song['name'] ?? 'No title',
            'image': imageUrl,
            'previewUrl': song['previewUrl'] ?? '', // Ensure preview URL is present
            'duration': duration, // Ensure duration is present
          };
        }).toList();
      });
    } catch (e) {
      print('Error searching songs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _onSongSelected(Map<String, dynamic> song) {
    setState(() {
      if (_selectedSong == song) {
        _selectedSong = null;
        widget.onAddSound(null); // Callback với giá trị null để thông báo bỏ chọn
      } else {
        _selectedSong = song;
        widget.onAddSound(song); // Callback với bài hát đã chọn
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) {
                      _fetchSongs(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your song name...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Màu nền xanh dương
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    'Search',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    final query = _searchController.text;
                    _fetchSongs(query);
                  },
                ),
              ],
            ),
          ),
          // Các category
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'];
                      });
                      _fetchSongsForCategory(_selectedCategory); // Tải bài hát theo category
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.0),
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected ? Colors.white : category['color'],
                            size: 20,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Danh sách nhạc
          Expanded(
            child: _isLoading
                ? Center(
              child: Lottie.asset(
                'assets/Animated/loading.json', // Path to your no data animation
                width: 150,
                height: 150,
              ),
            )
                : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final imageUrl = song['image'] as String?;
                final duration = song['duration'] as String?;
                final isSelected = _selectedSong != null &&
                    song['name'] == _selectedSong!['name'] &&
                    song['previewUrl'] == _selectedSong!['previewUrl'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Icon(Icons.music_note, color: Colors.white)
                        : null,
                  ),
                  title: Text(song['name'] ?? 'No title'),
                  subtitle: Text(duration ?? '0:00'), // Hiển thị thời gian bài hát
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        IconButton(
                          icon: Icon(Icons.content_cut),
                          color: Colors.black,
                          onPressed: () {
                            // Xử lý khi nhấn vào icon cây kéo
                            print('Scissors icon pressed');
                          },
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.red : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          isSelected ? 'Remove Sound' : 'Add Sound',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: () {
                          _onSongSelected(song); // Xử lý chọn hoặc gỡ bỏ bài hát
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Xử lý khi nhấn vào bài hát
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
