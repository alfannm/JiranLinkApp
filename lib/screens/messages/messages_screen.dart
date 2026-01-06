import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/messages_provider.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<MessagesProvider>().threads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: threads.isEmpty
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
              itemCount: threads.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppTheme.border,
              ),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final timeAgo =
                    DateFormat('MMM d, h:mm a').format(thread.lastTimestamp);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: thread.otherUserAvatar != null
                        ? NetworkImage(thread.otherUserAvatar!)
                        : null,
                    backgroundColor: AppTheme.primary,
                    child: thread.otherUserAvatar == null
                        ? Text(
                            thread.otherUserName.isNotEmpty
                                ? thread.otherUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.otherUserName,
                          style: TextStyle(
                            color: AppTheme.foreground,
                            fontWeight: thread.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (thread.unreadCount > 0)
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
                      if (thread.itemTitle != null)
                        Text(
                          thread.itemTitle!,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        thread.lastMessage,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontWeight: thread.unreadCount > 0
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
                          chatId: thread.id,
                          otherUserId: thread.otherUserId,
                          otherUserName: thread.otherUserName,
                          otherUserAvatar: thread.otherUserAvatar,
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
