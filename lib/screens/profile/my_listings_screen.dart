import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/item_card.dart';
import '../item_details/item_detail_screen.dart';
import '../../models/item.dart';
import '../post_item/post_item_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final all = context.watch<ItemsProvider>().allItems;
    final myListings = currentUser == null
        ? <Item>[]
        : all.where((item) => item.owner.id == currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: AppTheme.cardBackground,
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
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: myListings.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: myListings[index],
                  isFavorite:
                      false, // My listings don't need fav toggle usually
                  onToggleFavorite: () {},
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ItemDetailScreen(item: myListings[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
