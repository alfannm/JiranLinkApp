import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/user.dart' as app;

// Tracks user favorites and keeps them in sync with Firestore.
class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _favoriteIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;
  app.User? _currentUser;

  // Current favorite item ids.
  Set<String> get favoriteIds => _favoriteIds;

  // Updates the active user and subscribes to favorites.
  void setUser(app.User? user) {
    if (user?.id == _currentUser?.id) return;
    _currentUser = user;
    _favoriteIds.clear();
    _favoritesSub?.cancel();
    _favoritesSub = null;

    if (_currentUser == null) {
      notifyListeners();
      return;
    }

    _favoritesSub = _db
        .collection('users')
        .doc(_currentUser!.id)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      _favoriteIds
        ..clear()
        ..addAll(snapshot.docs.map((d) => d.id));
      notifyListeners();
    });
  }

  // Returns true when an item is favorited.
  bool isFavorite(String itemId) {
    return _favoriteIds.contains(itemId);
  }

  // Adds or removes a favorite item.
  Future<void> toggleFavorite(String itemId) async {
    final user = _currentUser;
    if (user == null) return;

    final docRef =
        _db.collection('users').doc(user.id).collection('favorites').doc(itemId);

    if (_favoriteIds.contains(itemId)) {
      await docRef.delete();
    } else {
      await docRef.set({'createdAt': DateTime.now()});
    }
  }

  // Filters all items down to favorites.
  List<Item> getFavoriteItems(List<Item> allItems) {
    return allItems.where((item) => _favoriteIds.contains(item.id)).toList();
  }

  // Cleans up Firestore subscriptions.
  @override
  void dispose() {
    _favoritesSub?.cancel();
    super.dispose();
  }
}
