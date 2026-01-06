import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/item_card.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/items_provider.dart';
import '../item_details/item_detail_screen.dart';
import '../main_navigation.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final items = context.watch<ItemsProvider>().allItems;
    final favoriteItems = favorites.getFavoriteItems(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: favoriteItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: AppTheme.mutedForeground),
                  const SizedBox(height: 16),
                  const Text('No favorites yet',
                      style: TextStyle(
                          fontSize: 18, color: AppTheme.mutedForeground)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(
                              initialIndex: 1,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Browse Items'))
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final item = favoriteItems[index];
                final heroTag = 'favorites-${item.id}';
                return ItemCard(
                  item: item,
                  heroTag: heroTag,
                  isFavorite: true,
                  onToggleFavorite: () {
                    favorites.toggleFavorite(item.id);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(
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
