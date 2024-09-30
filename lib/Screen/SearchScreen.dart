import 'dart:convert';

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/OtherUserScreen.dart';
import 'package:Doune/Screen/SearchResultScreen.dart'; // Adjust the import path as needed
import 'package:Doune/models/users.dart'; // Adjust the import path as needed
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<List<Users>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print('API Response: $data'); // Print the entire response

      List<Users> users = [];

      // Lấy user ID của người dùng hiện tại
      final currentUserId = await UserInfoProvider().getUserID();

      for (var userJson in data) {
        print('User JSON from API: $userJson'); // Print each user JSON
        Users user = Users.fromJson(userJson);

        // Kiểm tra xem người dùng này có bị block không
        final isBlocked = await isUserBlocked(currentUserId!, user.userID);

        if (!isBlocked) {
          users.add(user); // Chỉ thêm vào danh sách nếu không bị block
        }
      }

      return users;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<bool> isUserBlocked(int currentUserId, int userId) async {
    final String baseUrl = 'http://10.0.2.2:5000';

    // Yêu cầu đầu tiên
    final response1 = await http.get(Uri.parse('$baseUrl/check_blocked/$currentUserId/$userId'));

    // Yêu cầu thứ hai
    final response2 = await http.get(Uri.parse('$baseUrl/check_blocked/$userId/$currentUserId'));

    // Kiểm tra phản hồi từ yêu cầu đầu tiên
    if (response1.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response1.body);
      print('Check Blocked Response (1): $data'); // In phản hồi
      return data['is_blocked'] == true; // Trả về true nếu bị chặn
    }
    // Kiểm tra phản hồi từ yêu cầu thứ hai
    else if (response2.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response2.body);
      print('Check Blocked Response (2): $data'); // In phản hồi khác
      return data['is_blocked'] == true; // Trả về true nếu bị chặn
    } else {
      throw Exception('Failed to check if user is blocked');
    }
  }
}

Future<void> recordSearchKeyword(String keyword, int userid) async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:5000/search'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'keyword': keyword,
      'user_id': userid,  // Đảm bảo tên trường là 'user_email'
    }),
  );

  if (response.statusCode != 200) {
    print('Failed response: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to record search keyword');
  }
}

Future<List<String>> fetchTopSearches() async {
  final response = await http.get(Uri.parse('http://10.0.2.2:5000/top-search'));

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => item['keyword'] as String).toList();
  } else {
    throw Exception('Failed to load top searches');
  }
}

class SearchScreen extends StatefulWidget {
  final bool isSignedIn;
  const SearchScreen({required this.isSignedIn, Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Users>> usersFuture;
  List<String> _topSearches = [];
  List<String> recentSearches = [];
  List<String> suggestions = ['Suggestion 1', 'Suggestion 2', 'Suggestion 3']; // Example suggestions
  final TextEditingController _searchController = TextEditingController();
  bool _showAllRecentSearches = false; // To manage showing all recent searches
  bool _isLoading = true;
  bool _hasError = false;
  final UserInfoProvider userInfoProvider = UserInfoProvider();

  @override
  void initState() {
    super.initState();
    _loadTopSearches();
    usersFuture = ApiService().fetchUsers();
    _loadRecentSearches();
  }

  Future<void> _loadTopSearches() async {
    try {
      final searches = await fetchTopSearches();
      setState(() {
        _topSearches = searches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  void _addRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!recentSearches.contains(query)) {
        recentSearches.insert(0, query);
        prefs.setStringList('recentSearches', recentSearches);
        if (widget.isSignedIn) {
          recordSearchKeyword(query, userInfoProvider.getUserID() as int);
        }
      }
    });
  }

  void _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.remove(query);
      prefs.setStringList('recentSearches', recentSearches);
    });
  }

  void _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.clear();
      prefs.remove('recentSearches');
    });
  }

  void _toggleShowAllRecentSearches() {
    setState(() {
      _showAllRecentSearches = !_showAllRecentSearches;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding for the screen
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // Space below the search box
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.lightBlueAccent),
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _buildHintText(), // Set hintText with popular searches
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Colors.black, // Border color
                              width: 4.0, // Border thickness
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Colors.blue, // Border color when focused
                              width: 2.0, // Border thickness when focused
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {}); // Trigger a rebuild to clear the search results
                            },
                          )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {}); // Trigger a rebuild when the input changes
                        },
                      ),
                    ),
                    SizedBox(width: 8.0), // Spacing between TextField and button
                    TextButton(
                      onPressed: () async {
                        final searchQuery = _searchController.text;
                        if (searchQuery.isNotEmpty) {
                          _addRecentSearch(searchQuery);

                          if (widget.isSignedIn) {
                            try {
                              final userid = await userInfoProvider.getUserID();
                              if (userid != null) {
                                await recordSearchKeyword(searchQuery, userid);
                              }
                            } catch (e) {
                              print('Error getting email: $e');
                            }
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchResultScreen(), // Pass the query to the next screen if needed
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Search',
                        style: TextStyle(
                            color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold
                        ), // Set text color to blue
                      ),
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(
                          fontSize: 16, // Font size
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _searchController.text.isEmpty
                    ? _buildRecentSearches() // Show recent searches if the search field is empty
                    : _buildAutocomplete(), // Show autocomplete if there is a search query
              ),
            ],
          ),
        ),
      ),
    );
  }


// Helper function to build hint text from top searches
  String _buildHintText() {
    if (_topSearches.isEmpty) {
      return 'Search...'; // Default hint text if no top searches
    }
    // Combine the top searches into a single string for hintText
    final hint = _topSearches.take(1).join(', ');
    return '$hint'; // Customize the hint text as needed
  }

  Widget _buildAutocomplete() {
    final query = _searchController.text.toLowerCase();
    final normalizedQuery = query.replaceAll('@', '').trim();

    return FutureBuilder<List<Users>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              'assets/Animated/loading.json',
              width: 100,
              height: 100,
            ),
          );
        } else if (snapshot.hasError) {
          print('Error fetching users: ${snapshot.error}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your connection has been lost. Please check your network connection.'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return Center(
            child: Lottie.asset(
              'assets/Animated/loading.json',
              width: 100,
              height: 100,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Lottie.asset(
              'assets/Animated/loading.json',
              width: 100,
              height: 100,
            ),
          );
        }

        final users = snapshot.data!;
        final filteredUsers = users.where((user) {
          final userName = user.fullName.toLowerCase();
          return userName.contains(normalizedQuery);
        }).toList();

        final filteredRecentSearches = recentSearches.where((search) {
          return search.toLowerCase().contains(normalizedQuery);
        }).toList();

        final filteredTopSearches = _topSearches.where((search) {
          return search.toLowerCase().contains(normalizedQuery);
        }).toList();

        final allResults = <Widget>[
          if (filteredUsers.isNotEmpty)
            ...filteredUsers.map((user) {
              final userid = user.userID;
              final verified = user.verified;
              final imageUrl = user.profilePicture.isNotEmpty
                  ? 'http://10.0.2.2:5000/download/avatar/${user.profilePicture}'
                  : 'assets/default_profile_pic.png';
              print('search screen : $imageUrl');
              return ListTile(
                leading: Icon(Icons.call_made_outlined, color: Colors.red),
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    children: [
                      // Highlight the search result
                      ..._highlightSearchResult(user.fullName, query),
                      // Add a tick if the user is verified
                      if (user.verified)
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4.0), // Add some spacing
                            child: Icon(
                              Icons.verified, // Tick icon
                              color: Colors.blue, // Color for the tick
                              size: 18, // Size of the tick
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing: CircleAvatar(
                  backgroundImage: imageUrl.startsWith('http')
                      ? CachedNetworkImageProvider(imageUrl)
                      : AssetImage(imageUrl) as ImageProvider,
                  radius: 22,
                ),
                onTap: () {
                  _addRecentSearch(user.fullName);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherUserScreen(UserId: userid),
                    ),
                  );
                },
              );
            }).toList(),

          // Display filtered recent searches
          if (filteredRecentSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '  Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...filteredRecentSearches.map((search) {
                    return ListTile(
                      leading: Icon(Icons.access_time_filled, color: Colors.redAccent),
                      title: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          children: _highlightSearchResult(search, query),
                        ),
                      ),
                      onTap: () {
                        _searchController.text = search;
                        setState(() {}); // Trigger a rebuild to show autocomplete results
                      },
                    );
                  }).toList(),
                ],
              ),
            ),

          // Display filtered popular searches
          if (filteredTopSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '  Popular Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...filteredTopSearches.map((search) {
                    return ListTile(
                      leading: Icon(Icons.local_fire_department, size: 20, color: Colors.redAccent),
                      title: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          children: _highlightSearchResult(search, query),
                        ),
                      ),
                      onTap: () {
                        _searchController.text = search;
                        setState(() {}); // Trigger a rebuild to show autocomplete results
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
        ];

        // If no results found
        if (allResults.isEmpty) {
          return Center(
            child: Text('No results found'),
          );
        }

        return ListView(
          children: allResults,
        );
      },
    );
  }

  List<TextSpan> _highlightSearchResult(String text, String query) {
    final List<TextSpan> spans = [];
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (queryLower.isEmpty) {
      // If there's no query, return the text as is
      return [TextSpan(text: text)];
    }

    int startIndex = 0;
    while (startIndex < text.length) {
      final index = textLower.indexOf(queryLower, startIndex);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(startIndex)));
        break;
      }

      if (index > startIndex) {
        spans.add(TextSpan(text: text.substring(startIndex, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(color: Colors.lightBlueAccent), // Highlight color
      ));

      startIndex = index + query.length;
    }

    return spans;
  }

  Widget _buildRecentSearches() {
    final visibleRecentSearches = _showAllRecentSearches
        ? recentSearches
        : recentSearches.take(3).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // Hiển thị danh sách các tìm kiếm gần đây
              ...visibleRecentSearches.map((search) => ListTile(
                leading: Icon(Icons.access_time_filled, color: Colors.grey),
                title: Text(search,style: TextStyle(fontSize: 16),),
                trailing: IconButton(
                  icon: Icon(Icons.close_rounded),
                  onPressed: () => _removeRecentSearch(search),
                ),
                onTap: () {
                  _searchController.text = search;
                  setState(() {}); // Trigger a rebuild to show autocomplete results
                },
              )).toList(),

              // Hiển thị tùy chọn "More" nếu có nhiều hơn 3 tìm kiếm và không hiển thị tất cả
              if (recentSearches.length > 3 && !_showAllRecentSearches)
                ListTile(
                  title: Center(child: Text('More')),
                  onTap: _toggleShowAllRecentSearches,
                ),

              // Hiển thị nút "Clear Recent Searches" ngay sau mục "More" nếu tất cả đã được hiển thị
              if (_showAllRecentSearches && recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextButton(
                    onPressed: _clearRecentSearches,
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              if (_isLoading)
                Center(
                  child: Lottie.asset(
                    'assets/Animated/loading.json',
                    width: 150,
                    height: 150,
                  ),
                ),
              if (_hasError)
                Center(
                  child: Lottie.asset(
                    'assets/Animated/loading.json',
                    width: 150,
                    height: 150,
                  ),
                ),
              if (_topSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center align children horizontally
                    children: [
                      Container(
                        width: double.infinity, // Makes the container take full width
                        padding: EdgeInsets.all(8.0), // Add padding inside the container
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blueGrey], // Gradient colors
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8.0), // Optional: rounded corners
                        ),
                        child: Text(
                          'Popular Searches',
                          textAlign: TextAlign.center, // Center align text
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color for better contrast
                          ),
                        ),
                      ),
                      ..._topSearches.asMap().entries.map((entry) {
                        int index = entry.key;
                        String search = entry.value;
                        bool isTopThree = index < 3;

                        return ListTile(
                          leading: Icon(Icons.local_fire_department ,size: 20,color: Colors.redAccent,),
                          title: Text(
                            search,
                            style: TextStyle(fontSize: 18,
                              color: isTopThree ? Colors.redAccent : Colors.black,
                            ),
                          ),
                          trailing: Icon(Icons.search_rounded,size: 25,color: Colors.lightBlueAccent),
                          onTap: () {
                            _searchController.text = search;
                            setState(() {}); // Trigger a rebuild to show autocomplete results
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
