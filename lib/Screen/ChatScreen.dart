import 'dart:convert';

import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class Chat {
  final String content;
  final DateTime time;

  const Chat({required this.content, required this.time});

  // Factory constructor to create a Chat instance from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      content: json['content'] ?? '',
      time: DateTime.parse(json['time'] as String),
    );
  }

  // Method to convert a Chat instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'time': time.toIso8601String(), // Convert DateTime to ISO8601 format
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
  socket_io.Socket? socket;
  final Logger _logger = Logger();
  List<Chat> chats = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _initializeSocket(); // Call _initializeSocket() here to reconnect the socket
    _scrollController.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.position.maxScrollExtent;
      // Only scroll if the user is already at the bottom or within a certain threshold
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100) {
        _scrollController.animateTo(
          offset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _initializeSocket() {
    socket = socket_io.io(
      'http://10.0.2.2:5000',
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socket?.on('connect', (_) => _logger.i('Connected'));
    socket?.on('disconnect', (_) => _logger.i('Disconnected'));
    socket?.on('chat', (data) {
      setState(() {
        chats = [Chat.fromJson(data), ...chats];
      });
    });
  }

  void sendChat() {
    if (_messageController.text.isNotEmpty) {
      if (socket?.connected ?? false) {
        // Socket is connected, send the message
        final chat = Chat(content: _messageController.text, time: DateTime.now());
        socket?.emit('chat', chat.toJson());
        _messageController.clear();
        setState(() {
          chats = [chat, ...chats];
        });
      } else {
        // Socket is not connected, reconnect and then send the message
        _initializeSocket();
        Future.delayed(Duration(milliseconds: 500), () {
          sendChat(); // Call sendChat again after reconnecting
        });
      }
    }
  }

  @override
  void dispose() {
    socket?.close();
    socket?.dispose(); // Add this line to dispose of the socket
    _messageController.dispose();
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

  Future<void> _sendMessage(int senderId, int receiverId, String message) async {
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
          padding: EdgeInsets.only(top: 5),
          child: AppBar(
            leading: GestureDetector(
              onTap: () {
                socket?.close(); // Close the socket when the back button is clicked
                Navigator.pop(context); // Go back to the previous screen
              },
              child: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.lightBlueAccent,),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      body: FutureBuilder<int?>(
        future: widget.userId,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          } else if (!userSnapshot.hasData || userSnapshot.data == null) {
            return Center(child: Text('User ID not found'));
          } else {
            final resolvedUserId = userSnapshot.data!;

            return FutureBuilder<List<dynamic>>(
              future: _fetchMessages(resolvedUserId),
              builder: (context, messageSnapshot) {
                if (messageSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (messageSnapshot.hasError) {
                  return Center(child: Text('Error: ${messageSnapshot.error}'));
                } else if (!messageSnapshot.hasData || messageSnapshot.data!.isEmpty) {
                  return Center(child: Text('No messages'));
                } else {
                  final messages = messageSnapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isOutgoing = message['sender_id'] == resolvedUserId;

                            return Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                                child: ClipPath(
                                  clipper: isOutgoing ? LowerNipMessageClipper(MessageType.send) : UpperNipMessageClipper(MessageType.receive),
                                  child: Container(
                                    padding: EdgeInsets.all(15),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOutgoing ? Colors.blue : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      message['text'] ?? 'No content',
                                      style: TextStyle(color: isOutgoing ? Colors.white : Colors.black),
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(height: 2, color: Colors.black),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(Icons.add_circle, color: Colors.lightBlueAccent, size: 30,),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(Icons.emoji_emotions, color: Colors.lightBlueAccent, size: 30,),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: TextFormField(
                                  controller: _messageController,
                                  focusNode: _focusNode, // Add the FocusNode
                                  decoration: InputDecoration(
                                    hintText: "Type your message...",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: IconButton(
                                icon: Icon(Icons.send_rounded, color: Colors.lightBlueAccent, size: 30,),
                                onPressed: () {
                                  _sendMessage(resolvedUserId, widget.contactId, _messageController.text);
                                  sendChat();
                                  _messageController.clear();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          }
        },
      ),

    );
  }
}
