import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = MockData.mockMessages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: messages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.mutedForeground,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a conversation with item owners',
                    style: TextStyle(color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              itemBuilder: (context, index) {
                final message = messages[index];
                final timeAgo =
                    DateFormat('MMM d, h:mm a').format(message.timestamp);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: message.from.avatar != null
                        ? NetworkImage(message.from.avatar!)
                        : null,
                    backgroundColor: AppTheme.primary,
                    child: message.from.avatar == null
                        ? Text(
                            message.from.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.from.name,
                          style: TextStyle(
                            color: AppTheme.foreground,
                            fontWeight: message.unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (message.unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.destructive,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.item != null)
                        Text(
                          message.item!.title,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        message.lastMessage,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontWeight: message.unread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Text(
                    timeAgo,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUser: message.from,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
