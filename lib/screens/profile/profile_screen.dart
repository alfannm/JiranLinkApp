import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/items_provider.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'incoming_requests_screen.dart';
import 'my_listings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final itemsProvider = context.watch<ItemsProvider>();
    final bookingsProvider = context.watch<BookingsProvider>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myListings =
        itemsProvider.allItems.where((i) => i.owner.id == user.id).length;
    bool isSuccessful(BookingStatus status) {
      return status == BookingStatus.accepted ||
          status == BookingStatus.pendingPickup ||
          status == BookingStatus.active ||
          status == BookingStatus.completed;
    }

    final myRentals = bookingsProvider.bookings.where((booking) {
      final ownerIdMatch = booking.ownerId == user.id;
      final ownerEmailMatch = user.email.isNotEmpty &&
          booking.owner.email.isNotEmpty &&
          booking.owner.email == user.email;
      return (ownerIdMatch || ownerEmailMatch) &&
          isSuccessful(booking.status);
    }).length;
    final borrowed = bookingsProvider.bookings.where((booking) {
      final borrowerIdMatch = booking.borrowerId == user.id;
      final borrowerEmailMatch = user.email.isNotEmpty &&
          booking.borrower.email.isNotEmpty &&
          booking.borrower.email == user.email;
      return (borrowerIdMatch || borrowerEmailMatch) &&
          isSuccessful(booking.status);
    }).length;
    final hasIncomingRequests = bookingsProvider.pendingRequestsCount > 0 ||
        bookingsProvider.pendingOwnerPaymentCount > 0;
    final hasBookingUpdates = bookingsProvider.myBookings.any((booking) {
      final needsPayment = booking.status == BookingStatus.accepted &&
          booking.paymentStatus == PaymentStatus.pending;
      final needsReceive = booking.status == BookingStatus.pendingPickup;
      return needsPayment || needsReceive;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              clipBehavior: Clip.hardEdge,
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
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        user.district,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Joined ${user.joinDate.month}/${user.joinDate.day}/${user.joinDate.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard('$myListings', 'Items'),
                      const SizedBox(width: 16),
                      _buildStatCard('$myRentals', 'Rentals'),
                      const SizedBox(width: 16),
                      _buildStatCard('$borrowed', 'Borrowed'),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items
            const SizedBox(height: 24),
            _buildMenuItem(
              context,
              icon: Icons.favorite_outline,
              title: 'Favorites',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'My Bookings',
              trailing: _buildMenuTrailing(showDot: hasBookingUpdates),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_none_outlined,
              title: 'Incoming Requests',
              trailing: _buildMenuTrailing(showDot: hasIncomingRequests),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IncomingRequestsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.storefront_outlined,
              title: 'My Listings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyListingsScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 32, thickness: 8, color: AppTheme.background),

            _buildSectionHeader('Settings'),
            _buildMenuItem(
              context,
              icon: Icons.verified_user_outlined,
              title: 'Verification Status',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verification Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your account is verified. Contact support if you need to re-verify or update documents.',
                            style: TextStyle(color: AppTheme.mutedForeground),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
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
                    authProvider.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.destructive,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.foreground, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right,
              color: AppTheme.mutedForeground, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildMenuTrailing({required bool showDot}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.destructive,
              shape: BoxShape.circle,
            ),
          ),
        const Icon(Icons.chevron_right,
            color: AppTheme.mutedForeground, size: 20),
      ],
    );
  }
}
