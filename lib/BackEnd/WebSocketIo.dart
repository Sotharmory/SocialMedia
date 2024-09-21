import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void initSocket() {
    socket = IO.io('http://10.0.2.2:5000', IO.OptionBuilder()
        .setTransports(['websocket']) // Sử dụng WebSocket
        .build());

    socket.onConnect((_) {
      print('Connected to socket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });

    // Lắng nghe sự kiện tin nhắn mới
    socket.on('new_message', (data) {
      print('Received new message: $data');
      // Xử lý tin nhắn mới
    });
  }

  void sendMessage(int senderId, int receiverId, String message) {
    socket.emit('send_message', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
    });
  }
}