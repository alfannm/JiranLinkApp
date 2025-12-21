import 'package:flutter/foundation.dart';
import '../models/item.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String itemId) {
    return _favoriteIds.contains(itemId);
  }

  void toggleFavorite(String itemId) {
    if (_favoriteIds.contains(itemId)) {
      _favoriteIds.remove(itemId);
    } else {
      _favoriteIds.add(itemId);
    }
    notifyListeners();
  }

  List<Item> getFavoriteItems(List<Item> allItems) {
    return allItems.where((item) => _favoriteIds.contains(item.id)).toList();
  }
}
