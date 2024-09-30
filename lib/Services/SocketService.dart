import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rxdart/rxdart.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });

    socket.on('connect_error', (error) {
      print('Connection Error: $error');
    });

    socket.on('connect_timeout', (timeout) {
      print('Connection Timeout: $timeout');
    });

    socket.on('new_message', (data) {
      print('New message received: $data');
      // Notify listeners about the new message
      _newMessageController.add(data);
    });

    socket.on('update_messenger_list', (data) {
      print('Messenger list update received: $data');
      // Notify listeners about the messenger list update
      _updateMessengerListController.add(data);
    });
  }

  final _newMessageController = BehaviorSubject<dynamic>();
  Stream<dynamic> get newMessageStream => _newMessageController.stream;

  final _updateMessengerListController = BehaviorSubject<dynamic>();
  Stream<dynamic> get updateMessengerListStream =>
      _updateMessengerListController.stream;

  void joinRoom(int userId) {
    socket.emit('join', {'user_id': userId});
  }

  void sendMessage(Map<String, dynamic> message) {
    socket.emit('new_message', message);
  }

  void onNewMessage(Function(dynamic) callback) {
    socket.on('new_message', callback);
  }

  void onUpdateMessengerList(Function(dynamic) callback) {
    socket.on('update_messenger_list', callback);
  }

  void dispose() {
    _newMessageController.close();
    _updateMessengerListController.close();
    socket.dispose();
  }
}
