import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Items'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            SizedBox(height: 16),
            Text(
              'Browse Screen',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Filter items by category and distance',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
