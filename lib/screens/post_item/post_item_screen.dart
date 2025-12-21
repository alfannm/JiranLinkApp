import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PostItemScreen extends StatelessWidget {
  const PostItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Item'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            SizedBox(height: 16),
            Text(
              'Post Item Screen',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create new rental or service listing',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
