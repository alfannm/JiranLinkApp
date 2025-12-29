import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../data/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/item_card.dart';
import '../../models/item.dart';
import '../item_details/item_detail_screen.dart';
import '../main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser ?? MockData.currentUser;

    final nearbyItems = itemsProvider.getNearbyItems(currentUser.district, 4);
    final featuredItems = itemsProvider.getFeaturedItems(6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom Green Header
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF10B981), // Primary Green
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to JiranLink',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share tools, skills & services with your neighbors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentUser.district,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search for items or services...',
                        hintStyle:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Color(0xFF9CA3AF), size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        isDense: true,
                      ),
                      onChanged: (query) {
                        itemsProvider.setSearchQuery(query);
                      },
                      onSubmitted: (query) {
                        itemsProvider.setSearchQuery(query);
                        MainNavigation.of(context)?.switchToTab(1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryItem(
                            context, Icons.inventory_2_outlined, 'All', null),
                        const SizedBox(width: 16),
                        _buildCategoryItem(context, Icons.construction_outlined,
                            'Tools', ItemCategory.tools),
                        const SizedBox(width: 16),
                        _buildCategoryItem(context, Icons.devices_outlined,
                            'Appliances', ItemCategory.appliances),
                        const SizedBox(width: 16),
                        _buildCategoryItem(context, Icons.lightbulb_outline,
                            'Skills', ItemCategory.skills),
                        const SizedBox(width: 16),
                        _buildCategoryItem(
                            context,
                            Icons.business_center_outlined,
                            'Services',
                            ItemCategory.services),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nearby Items
          if (nearbyItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Near You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        MainNavigation.of(context)?.switchToTab(1);
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = nearbyItems[index];
                    return ItemCard(
                      item: item,
                      isFavorite: favoritesProvider.isFavorite(item.id),
                      onToggleFavorite: () {
                        favoritesProvider.toggleFavorite(item.id);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                  childCount: nearbyItems.length > 4 ? 4 : nearbyItems.length,
                ),
              ),
            ),
          ],

          // Featured Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      MainNavigation.of(context)?.switchToTab(1);
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.60,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = featuredItems[index];
                  return ItemCard(
                    item: item,
                    isFavorite: favoritesProvider.isFavorite(item.id),
                    onToggleFavorite: () {
                      favoritesProvider.toggleFavorite(item.id);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(item: item),
                        ),
                      );
                    },
                  );
                },
                childCount: featuredItems.length,
              ),
            ),
          ),

          // Kampung Spirit Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 32, 16, 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5), // Light green background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reviving the Kampung Spirit 🏡',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'JiranLink connects neighbors to share resources, save money, and build a stronger community. Borrow what you need, share what you have.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildTrustBadge('Verified Users'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Secure Payments'),
                      const SizedBox(width: 12),
                      _buildTrustBadge('Local Community'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, IconData icon, String label,
      ItemCategory? category) {
    final isSelected =
        context.watch<ItemsProvider>().selectedCategory == category;

    return GestureDetector(
      onTap: () {
        context.read<ItemsProvider>().setCategory(category);
        MainNavigation.of(context)?.switchToTab(1);
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 12, color: Color(0xFF059669)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
      ],
    );
  }
}
