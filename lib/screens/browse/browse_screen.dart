import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/items_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/item_card.dart';
import '../item_details/item_detail_screen.dart';
import 'map_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final items = itemsProvider.items;

    // Sync controller with provider if needed (e.g. initial load or external update)
    if (_searchController.text != itemsProvider.searchQuery) {
      _searchController.text = itemsProvider.searchQuery;
      // _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length)); // Optional: move cursor to end
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search items or services...',
                              prefixIcon: Icon(Icons.search,
                                  color: AppTheme.mutedForeground),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (query) {
                              itemsProvider.setSearchQuery(query);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.map_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MapScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton(
                          icon: Icons.location_on_outlined,
                          label: 'Detect Nearby',
                          isActive: itemsProvider.userLatitude != null,
                          onTap: () async {
                            final ok = await itemsProvider.detectAndSetUserLocation();
                            if (!mounted) return;
                            if (!ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not get location. Check GPS + permissions.')),
                              );
                              return;
                            }

                            // Set a reasonable default radius if none is set
                            itemsProvider.setRadiusFilter(itemsProvider.radiusFilter ?? 10);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterDropdown('All Distances'),
                        const SizedBox(width: 8),
                        _buildFilterDropdown('All Categories'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.border),

            // Results Count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${items.length} items found',
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: AppTheme.mutedForeground),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
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
                                builder: (context) =>
                                    ItemDetailScreen(item: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.foreground : AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppTheme.mutedForeground),
        ],
      ),
    );
  }
}
