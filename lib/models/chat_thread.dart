import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String id;
  final List<String> participants;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? itemId;
  final String? itemTitle;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.participants,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.itemId,
    this.itemTitle,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });

  factory ChatThread.fromFirestore({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
    final avatars = Map<String, dynamic>.from(data['participantAvatars'] ?? {});
    final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});

    return ChatThread(
      id: doc.id,
      participants: participants,
      otherUserId: otherUserId,
      otherUserName: names[otherUserId] ?? 'User',
      otherUserAvatar: avatars[otherUserId],
      itemId: data['itemId'],
      itemTitle: data['itemTitle'],
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp:
          (data['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: (unreadCounts[currentUserId] as num?)?.toInt() ?? 0,
    );
  }
}
