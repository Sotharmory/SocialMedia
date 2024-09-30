import 'dart:convert';
import 'dart:async';
import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/ChatScreen.dart';
import 'package:Doune/Services/SocketService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

final baseUrl = 'http://10.0.2.2:5000';

Future<List<Map<String, dynamic>>> fetchUserMessages(int userId) async {
  final response = await http
      .get(Uri.parse('$baseUrl/Get_User_Messenger_List?user_id=$userId'));

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load messages');
  }
}

Future<Map<String, dynamic>> fetchUserById(int contactId) async {
  final response = await http.get(Uri.parse('$baseUrl/user-by-id/$contactId'));

  if (response.statusCode == 200) {
    final userData = json.decode(response.body);

    if (userData['ProfilePictureURL'] != null) {
      userData['ProfilePictureURL'] =
          '$baseUrl/download/avatar/${userData['ProfilePictureURL']}';
    }

    return userData;
  } else {
    throw Exception('Failed to load user');
  }
}

String _formatTimestamp(String timestamp) {
  try {
    final messageDate = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(messageDate);

    if (difference.inSeconds < 60) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(messageDate); // Day of the week
    } else {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(messageDate);
    }
  } catch (e) {
    return 'Invalid Date';
  }
}

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final userInfoProvider = UserInfoProvider();
  final socketService = SocketService();
  List<Map<String, dynamic>> messages = [];
  late StreamSubscription _newMessageSubscription;
  late StreamSubscription _updateMessengerListSubscription;
  final _messagesSubject = BehaviorSubject<List<Map<String, dynamic>>>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _loadMessages();
  }

  void _setupSocket() async {
    final userId = await userInfoProvider.getUserID();
    if (userId == null) return;

    _newMessageSubscription = socketService.newMessageStream
        .debounceTime(Duration(milliseconds: 300))
        .listen((data) {
      final currentMessages = _messagesSubject.valueOrNull ?? [];
      currentMessages.insert(0, data);
      _messagesSubject.add(currentMessages);
      _listKey.currentState
          ?.insertItem(0, duration: Duration(milliseconds: 300));
    });

    _updateMessengerListSubscription = socketService.updateMessengerListStream
        .debounceTime(Duration(milliseconds: 300))
        .listen((data) {
      if (data['user_id'] == userId) {
        _loadMessages();
      }
    });

    socketService.joinRoom(userId);
  }

  Future<void> _loadMessages() async {
    final userId = await userInfoProvider.getUserID();
    if (userId != null) {
      try {
        final fetchedMessages = await fetchUserMessages(userId);
        _messagesSubject.add(fetchedMessages);
      } catch (e) {
        print('Error loading messages: $e');
      }
    }
  }

  @override
  void dispose() {
    _newMessageSubscription.cancel();
    _updateMessengerListSubscription.cancel();
    _messagesSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _messagesSubject.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data!;
            return AnimatedList(
              key: _listKey,
              initialItemCount: messages.length + 2, // Add 2 for the new items
              itemBuilder: (context, index, animation) {
                if (index == 0) {
                  return _buildSystemNotificationItem(context);
                } else if (index == 1) {
                  return _buildActivityItem(context);
                } else if (index - 2 < messages.length) {
                  final message = messages[index - 2];
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _buildMessageItem(context, message),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSystemNotificationItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle system notification tap
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            SizedBox(height: 15), // Reduced height
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              leading: Padding(
                padding:
                    EdgeInsets.only(left: 10), // Indent avatar to the right
                child: CircleAvatar(
                  child: Icon(Icons.notifications, color: Colors.white),
                  backgroundColor: Colors.blue,
                  radius: 30,
                ),
              ),
              title: Text(
                'System Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'View system notifications',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Handle activity item tap
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            SizedBox(height: 15), // Reduced height
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              leading: Padding(
                padding:
                    EdgeInsets.only(left: 10), // Indent avatar to the right
                child: CircleAvatar(
                  child: Icon(Icons.local_activity, color: Colors.white),
                  backgroundColor: Colors.green,
                  radius: 30,
                ),
              ),
              title: Text(
                'Activity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'View recent activities',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, Map<String, dynamic> message) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserById(message['contact_id'] ?? 0),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return ListTile(title: Text('Error loading user'));
        } else if (!userSnapshot.hasData) {
          return ListTile(title: Text('User not found'));
        } else {
          final user = userSnapshot.data!;
          final contactName = user['FullName'] ?? 'Unknown User';
          final profilePictureUrl = user['ProfilePictureURL'] ?? '';
          final lastMessage = message['last_message'] ?? 'No message available';
          final truncatedMessage = lastMessage.length > 30
              ? '${lastMessage.substring(0, 30)}...'
              : lastMessage;
          final timestamp = message['timestamp'] ?? 'No time available';
          print('THOI GIAN: $timestamp');
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      contactName: contactName,
                      profilePictureUrl: profilePictureUrl,
                      contactId: message['contact_id'] ?? 0,
                      userId: userInfoProvider.getUserID(),
                    ),
                  ),
                ).then((_) => _loadMessages());
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Column(
                children: [
                  SizedBox(height: 3), // Reduced height
                  ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                    leading: Padding(
                      padding: EdgeInsets.only(
                          left: 10), // Indent avatar to the right
                      child: CircleAvatar(
                        backgroundImage: profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : AssetImage('assets/images/default_avatar.png')
                                as ImageProvider,
                        radius: 30,
                      ),
                    ),
                    title: Text(
                      contactName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      truncatedMessage,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
