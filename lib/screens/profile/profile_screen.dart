import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = MockData.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.cardBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        user.avatar != null ? NetworkImage(user.avatar!) : null,
                    backgroundColor: Colors.white,
                    child: user.avatar == null
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating} (${user.reviewCount} reviews)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.favorite_outline,
              title: 'My Favorites',
              onTap: () {
                // Navigate to favorites
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'My Bookings',
              onTap: () {
                // Navigate to bookings
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.inbox_outlined,
              title: 'Incoming Requests',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '0',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {
                // Navigate to requests
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'My Listings',
              onTap: () {
                // Navigate to my listings
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.history,
              title: 'Transaction History',
              onTap: () {
                // Navigate to history
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // Navigate to support
              },
            ),
            const Divider(height: 1, color: AppTheme.border),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: 'About JiranLink',
              onTap: () {
                // Navigate to about
              },
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    authProvider.logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.destructive,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.foreground),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.foreground),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.mutedForeground),
      onTap: onTap,
    );
  }
}
