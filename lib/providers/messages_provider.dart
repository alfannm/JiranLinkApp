import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_thread.dart';
import '../models/item.dart';
import '../models/user.dart' as app;

// Manages chat threads and message sending.
class MessagesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  app.User? _currentUser;
  List<ChatThread> _threads = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _threadsSub;

  // Current chat threads.
  List<ChatThread> get threads => _threads;
  // Total unread messages across threads.
  int get unreadCount =>
      _threads.fold(0, (total, t) => total + t.unreadCount);

  // Updates the active user and subscribes to threads.
  void setUser(app.User? user) {
    if (user?.id == _currentUser?.id) return;
    _currentUser = user;
    _threads = [];
    _threadsSub?.cancel();
    _threadsSub = null;

    if (_currentUser == null) {
      notifyListeners();
      return;
    }

    _threadsSub = _db
        .collection('chats')
        .where('participants', arrayContains: _currentUser!.id)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _threads = snapshot.docs
          .map((doc) => ChatThread.fromFirestore(
                doc: doc,
                currentUserId: _currentUser!.id,
              ))
          .toList();
      notifyListeners();
    });
  }

  // Builds a stable chat id for two users and an optional item.
  String buildChatId({
    required String userA,
    required String userB,
    String? itemId,
  }) {
    final ids = [userA, userB]..sort();
    final base = '${ids[0]}_${ids[1]}';
    return itemId == null || itemId.isEmpty ? base : '${base}_$itemId';
  }

  // Returns a message stream for a chat.
  Stream<QuerySnapshot<Map<String, dynamic>>> messageStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // Sends a new message and updates the thread summary.
  Future<void> sendMessage({
    String? chatId,
    required app.User otherUser,
    required String text,
    Item? item,
  }) async {
    final me = _currentUser;
    if (me == null) return;
    if (otherUser.id == me.id) {
      throw StateError('You cannot message yourself.');
    }

    final resolvedChatId = chatId ??
        buildChatId(
          userA: me.id,
          userB: otherUser.id,
          itemId: item?.id,
        );

    final chatRef = _db.collection('chats').doc(resolvedChatId);
    final msgRef = chatRef.collection('messages').doc();
    final now = DateTime.now();

    final chatData = {
      'participants': [me.id, otherUser.id],
      'participantNames': {
        me.id: me.name,
        otherUser.id: otherUser.name,
      },
      'participantAvatars': {
        me.id: me.avatar,
        otherUser.id: otherUser.avatar,
      },
      'itemId': item?.id,
      'itemTitle': item?.title,
      'lastMessage': text,
      'lastTimestamp': now,
      'unreadCounts': {
        me.id: 0,
        otherUser.id: FieldValue.increment(1),
      },
    };

    final messageData = {
      'senderId': me.id,
      'text': text,
      'timestamp': now,
    };

    await _db.runTransaction((txn) async {
      txn.set(chatRef, chatData, SetOptions(merge: true));
      txn.set(msgRef, messageData);
    });
  }

  // Marks a chat as read for the current user.
  Future<void> markChatRead(String chatId) async {
    final me = _currentUser;
    if (me == null) return;
    final chatRef = _db.collection('chats').doc(chatId);
    try {
      await chatRef.update({'unreadCounts.${me.id}': 0});
    } catch (_) {
      await chatRef.set(
        {
          'unreadCounts': {me.id: 0},
        },
        SetOptions(merge: true),
      );
    }
  }

  // Cleans up Firestore subscriptions.
  @override
  void dispose() {
    _threadsSub?.cancel();
    super.dispose();
  }
}
