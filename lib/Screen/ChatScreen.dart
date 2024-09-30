import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:custom_clippers/custom_clippers.dart'; // Add this import for the clippers
import 'package:Doune/Services/SocketService.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';

class Chat {
  final String content;
  final DateTime time;
  final int senderId; // Add senderId field

  const Chat(
      {required this.content,
      required this.time,
      required this.senderId}); // Update constructor

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      content: json['text'] ?? '',
      time: DateTime.parse(json['timestamp'] as String),
      senderId: json['sender_id'] ?? 0, // Parse senderId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'time': time.toIso8601String(),
      'sender_id': senderId, // Add senderId to JSON
    };
  }
}

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String profilePictureUrl;
  final int contactId;
  final Future<int?> userId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.profilePictureUrl,
    required this.contactId,
    required this.userId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late TextEditingController _messageController;
  final Logger _logger = Logger();
  List<Chat> chats = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final socketService = SocketService();
  late int resolvedUserId;
  final _chatsSubject = BehaviorSubject<List<Chat>>();
  bool _showGoDownButton = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController.addListener(_scrollListener);
    widget.userId.then((userId) {
      if (userId != null) {
        resolvedUserId = userId;
        socketService.joinRoom(resolvedUserId);
        _fetchMessages(resolvedUserId).then((messages) {
          if (mounted) {
            _chatsSubject.add(
                messages.map((message) => Chat.fromJson(message)).toList());
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
          }
        });
      } else {
        _logger.e('User ID is null');
      }
    });

    socketService.onNewMessage((data) {
      if (mounted) {
        final currentChats = _chatsSubject.valueOrNull ?? [];
        final newMessage = Chat.fromJson(data);
        if (newMessage.senderId == widget.contactId) {
          currentChats.add(newMessage);
          _chatsSubject.add(currentChats);
          _scrollToBottom();
        }
      }
    });

    // Scroll to bottom when entering the chat screen
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // At the top of the list
        setState(() {
          _showGoDownButton = true;
        });
      } else {
        // At the bottom of the list
        setState(() {
          _showGoDownButton = false;
        });
      }
    } else {
      setState(() {
        _showGoDownButton = true;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatsSubject.close();
    super.dispose();
  }

  Future<List<dynamic>> _fetchMessages(int userId) async {
    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:5000/get_conversation?user_id=$userId&contact_id=${widget.contactId}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      throw Exception('Error fetching messages');
    }
  }

  Future<void> _sendMessage(
      int senderId, int receiverId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Message sent successfully');
        socketService.sendMessage({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'text': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
        setState(() {
          chats.add(Chat(
              content: message,
              time: DateTime.now(),
              senderId: senderId)); // Update Chat constructor
        });
        _scrollToBottom();
      } else {
        _logger.e('Failed to send message: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: EdgeInsets.only(top: 0),
          child: AppBar(
            backgroundColor: Colors.lightBlueAccent,
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
              ),
            ),
            leadingWidth: 50,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.network(
                    widget.profilePictureUrl,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  widget.contactName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 25),
                child: Icon(Icons.call_rounded, size: 30),
              ),
              Padding(
                padding: EdgeInsets.only(right: 25),
                child: Icon(Icons.video_call_rounded, size: 30),
              ),
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.more_rounded),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<int?>(
            future: widget.userId,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: Lottie.asset('assets/Animated/loading.json',
                        height: 100));
              } else if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              } else if (!userSnapshot.hasData || userSnapshot.data == null) {
                return Center(child: Text('User ID not found'));
              } else {
                final resolvedUserId = userSnapshot.data!;

                return StreamBuilder<List<Chat>>(
                  stream: _chatsSubject.stream,
                  builder: (context, chatSnapshot) {
                    if (!chatSnapshot.hasData) {
                      return Center(
                          child: Lottie.asset('assets/Animated/loading.json',
                              height: 100));
                    }
                    final chats = chatSnapshot.data!;
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final isOutgoing =
                                  chat.senderId == resolvedUserId;
                              final showAvatar = (index == 0 ||
                                  chats[index - 1].senderId != chat.senderId);

                              return Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Align(
                                  alignment: isOutgoing
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Row(
                                    mainAxisAlignment: isOutgoing
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (!isOutgoing && showAvatar)
                                        Padding(
                                          padding: EdgeInsets.only(
                                              right:
                                                  10), // Move avatar to the left
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                widget.profilePictureUrl),
                                            radius: 20,
                                          ),
                                        ),
                                      Container(
                                        padding: EdgeInsets.all(15),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOutgoing
                                              ? Colors.lightBlueAccent
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                              20), // Rounded corners
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          chat.content,
                                          style: TextStyle(color: Colors.white),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Icon(
                                  Icons.add_circle,
                                  color: Colors.lightBlueAccent,
                                  size: 30,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Icon(
                                  Icons.emoji_emotions,
                                  color: Colors.lightBlueAccent,
                                  size: 30,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: TextFormField(
                                    controller: _messageController,
                                    focusNode: _focusNode,
                                    decoration: InputDecoration(
                                      hintText: "Type your message...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors
                                          .white, // Set background color to white
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color: Colors.lightBlueAccent,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    _sendMessage(
                                        resolvedUserId,
                                        widget.contactId,
                                        _messageController.text);
                                    _messageController.clear();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          if (_showGoDownButton)
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 -
                  28, // Center the button
              child: FloatingActionButton(
                backgroundColor: Colors.lightBlueAccent,
                shape: CircleBorder(), // Make the button circular
                onPressed: _scrollToBottom,
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
