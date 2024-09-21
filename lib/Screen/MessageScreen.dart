import 'dart:convert';

import 'package:Doune/BackEnd/GetInfoUser.dart';
import 'package:Doune/Screen/ChatScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


final baseUrl = 'http://10.0.2.2:5000';

Future<List<Map<String, dynamic>>> fetchUserMessages(int userId) async {
  final response = await http.get(Uri.parse('$baseUrl/Get_User_Messenger_List?user_id=$userId'));

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
      userData['ProfilePictureURL'] = '$baseUrl/download/avatar/${userData['ProfilePictureURL']}';
    }

    return userData;
  } else {
    throw Exception('Failed to load user');
  }
}

String _formatTimestamp(String timestamp) {
  try {
    final messageDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(timestamp, true);
    final now = DateTime.now();
    final formatter = DateFormat('HH:mm');

    if (messageDate.year == now.year && messageDate.month == now.month && messageDate.day == now.day) {
      return formatter.format(messageDate);
    } else if (messageDate.isBefore(now) && now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE').format(messageDate);
    } else {
      return DateFormat('dd/MM/yyyy').format(messageDate);
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
  late IO.Socket socket;
  final userInfoProvider = UserInfoProvider();


  void _initializeSocket() async {
    try {
      final userId = await userInfoProvider.getUserID(); // Await the Future to get the userId
      if (userId == null) {
        print('User ID is null');
        return;
      }

      final socketUrl = 'http://10.0.2.2:5000/Get_User_Messenger_List?user_id=$userId';
      print('Connecting to $socketUrl');

      IO.Socket socket;

      if (kIsWeb) {
        // Configurations for Web platform
        socket = IO.io(socketUrl, IO.OptionBuilder().setTransports(['websocket']).build());
      } else {
        // Configurations for other platforms
        socket = IO.io(socketUrl, IO.OptionBuilder().setTransports(['websocket']).build());
      }

      socket.on('connect', (_) {
        print('Connected to server');
        _subscribeToMessages(); // Register to listen for new messages once connected
      });

      socket.on('connect_error', (error) {
        print('Connection error: $error');
      });

      socket.on('disconnect', (_) {
        print('Disconnected from server');
      });

      socket.on('reconnect', (attemptNumber) {
        print('Reconnected to server after $attemptNumber attempts');
      });

      socket.on('reconnect_attempt', (attemptNumber) {
        print('Attempting to reconnect: $attemptNumber');
      });

      socket.on('new_message', (data) {
        print('New message received: $data');
        setState(() {});
      });
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }



  void _subscribeToMessages() async {
    final userId = await userInfoProvider.getUserID();
    if (userId != null) {
      socket.emit('subscribe_to_messages', {'user_id': userId});
    }
  }

  Future<List<Map<String, dynamic>>> _loadMessages() async {
    final userId = await userInfoProvider.getUserID();
    if (userId != null) {
      return fetchUserMessages(userId);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search),
                    color: Colors.white,
                    iconSize: 36,
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'R E C E N T',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    buildRecentContact('Barry'),
                    SizedBox(width: 20),
                    buildRecentContact('John'),
                    // Add more users if needed
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Lottie.asset(
                          'assets/Animated/loading.json',
                          width: 150,
                          height: 150,
                          repeat: true,
                          animate: true,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No messages found'));
                    } else {
                      final messages = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final contactId = message['contact_id'] ?? 0;

                          return FutureBuilder<Map<String, dynamic>>(
                            future: fetchUserById(contactId),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (userSnapshot.hasError) {
                                return ListTile(
                                  title: Text(
                                      'Connection Lost. Please check your Internet connection'),
                                );
                              } else if (!userSnapshot.hasData) {
                                return ListTile(
                                  title: Text('User not found'),
                                );
                              } else {
                                final user = userSnapshot.data!;
                                final contactName = user['FullName'] ??
                                    'Unknown User';
                                final profilePictureUrl = user['ProfilePictureURL'] ??
                                    '';
                                final lastMessage = message['last_message'] ??
                                    'No message available';
                                final timestamp = message['timestamp'] ??
                                    'No time available';
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatScreen(
                                                contactName: contactName,
                                                profilePictureUrl: profilePictureUrl,
                                                contactId: contactId,
                                                userId: UserInfoProvider()
                                                    .getUserID(),
                                              ),
                                        ),
                                      );
                                    },
                                    splashColor: Colors.blue.withOpacity(0.2),
                                    highlightColor: Colors.lightBlueAccent,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 25),
                                        // Thay đổi khoảng cách ở đây
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 0),
                                          leading: CircleAvatar(
                                            backgroundImage: profilePictureUrl
                                                .isNotEmpty
                                                ? NetworkImage(
                                                profilePictureUrl)
                                                : AssetImage(
                                                'assets/images/default_avatar.png') as ImageProvider,
                                            radius: 30,
                                          ),
                                          title: Text(
                                            contactName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            lastMessage,
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          trailing: Text(
                                            timestamp,
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Divider(
                                            height: 1, color: Colors.grey[300]),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentContact(String name) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage('assets/images/default_avatar.png'),
          radius: 30,
        ),
        SizedBox(height: 5),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
