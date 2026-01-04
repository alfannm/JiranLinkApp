import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/item.dart';
import '../../models/user.dart' as app;
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final Item? item;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.item,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _chatId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;
  bool _sentInitial = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final messages = context.read<MessagesProvider>();
    final me = Provider.of<AuthProvider>(context).currentUser;
    if (me == null) return;

    if (_chatId == null) {
      _chatId = widget.chatId ??
          messages.buildChatId(
            userA: me.id,
            userB: widget.otherUserId,
            itemId: widget.item?.id,
          );
      _messagesStream = messages.messageStream(_chatId!);
    }

    if (!_sentInitial && widget.initialMessage != null) {
      _sentInitial = true;
      messages.sendMessage(
        chatId: _chatId,
        otherUser: app.User(
          id: widget.otherUserId,
          name: widget.otherUserName,
          email: '',
          phone: '',
          district: '',
          avatar: widget.otherUserAvatar,
          joinDate: DateTime.now(),
          rating: 0,
          reviewCount: 0,
        ),
        text: widget.initialMessage!,
        item: widget.item,
      );
    }

    if (_chatId != null) {
      messages.markChatRead(_chatId!);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final messages = context.read<MessagesProvider>();
    try {
      await messages.sendMessage(
        chatId: _chatId,
        otherUser: app.User(
          id: widget.otherUserId,
          name: widget.otherUserName,
          email: '',
          phone: '',
          district: '',
          avatar: widget.otherUserAvatar,
          joinDate: DateTime.now(),
          rating: 0,
          reviewCount: 0,
        ),
        text: text,
        item: widget.item,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0]
                      : '?')
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messagesStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load messages.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs.reversed.toList();
                      final me = context.read<AuthProvider>().currentUser;
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final senderId = data['senderId'];
                          final text = data['text'] ?? '';
                          final isMe = me != null && senderId == me.id;
                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppTheme.primary : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
