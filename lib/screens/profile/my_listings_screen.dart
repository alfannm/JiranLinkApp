import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/items_provider.dart';
import '../../widgets/item_card.dart';
import '../item_details/item_detail_screen.dart';
import '../../models/item.dart';
import '../post_item/post_item_screen.dart';

// Shows listings created by the current user.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  // Builds the listings screen layout.
  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final all = context.watch<ItemsProvider>().allItems;
    final favoritesProvider = context.watch<FavoritesProvider>();
    final myListings = currentUser == null
        ? <Item>[]
        : all.where((item) => item.owner.id == currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostItemScreen()),
              );
            },
          )
        ],
      ),
      body: myListings.isEmpty
          ? const Center(child: Text('No listings yet'))
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: myListings.length,
              itemBuilder: (context, index) {
                final item = myListings[index];
                final heroTag = 'my-listings-${item.id}';
                return ItemCard(
                  item: item,
                  heroTag: heroTag,
                  isFavorite: favoritesProvider.isFavorite(item.id),
                  onToggleFavorite: () {
                    favoritesProvider.toggleFavorite(item.id);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(
                          item: item,
                          heroTag: heroTag,
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
