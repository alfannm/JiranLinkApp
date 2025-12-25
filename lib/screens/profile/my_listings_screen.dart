import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/item_card.dart';
import '../item_details/item_detail_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock: Show items owned by current user (or some mock filter)
    // Using simple filter for now, assuming mockItems has owners.
    final myListings = MockData.mockItems
        .where((item) => item.owner.id == MockData.currentUser.id)
        .toList();

    // If empty for mock, just show all for demo purposes or First 2
    final displayItems =
        myListings.isEmpty ? MockData.mockItems.take(2).toList() : myListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppTheme.cardBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Post new item flow (already in MainNavigation, but shortcut here is nice)
              // Navigator.push...
            },
          )
        ],
      ),
      body: displayItems.isEmpty
          ? const Center(child: Text('No listings yet'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: displayItems[index],
                  isFavorite:
                      false, // My listings don't need fav toggle usually
                  onToggleFavorite: () {},
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ItemDetailScreen(item: displayItems[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
