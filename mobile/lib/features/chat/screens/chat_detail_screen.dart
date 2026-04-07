import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:ui'; // Để dùng con lăn chuột nếu cần

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late IO.Socket socket;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    // 10.0.2.2 là IP để máy ảo Android gọi về localhost máy tính
    socket = IO.io('http://10.0.2.2:3000', IO.OptionBuilder()
        .setTransports(['websocket'])
        .setQuery({'userName': 'Dũng'}) // Gửi tên mình lên
        .build());

    socket.onConnect((_) => debugPrint('✅ Đã kết nối Socket.io thành công!'));

    // Nghe tin nhắn từ Server trả về
    socket.on('receive_message', (data) {
      if (mounted) {
        setState(() {
          messages.add({
            "sender": data['sender'],
            "text": data['text'],
            "isMe": data['sender'] == "Dũng",
          });
        });
        // Tự động cuộn xuống cuối khi có tin mới
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      var msg = {"sender": "Dũng", "text": _controller.text.trim()};
      socket.emit('send_message', msg);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bác sĩ hỗ trợ 24/7", style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) => _buildChatBubble(messages[i]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isMe = msg['isMe'] ?? false;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2F80ED) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(
          msg['text'],
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Color(0xFF2F80ED)), onPressed: sendMessage),
        ],
      ),
    );
  }
}