import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/user.dart' as app;

class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _favoriteIds = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;
  app.User? _currentUser;

  Set<String> get favoriteIds => _favoriteIds;

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

  bool isFavorite(String itemId) {
    return _favoriteIds.contains(itemId);
  }

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

  List<Item> getFavoriteItems(List<Item> allItems) {
    return allItems.where((item) => _favoriteIds.contains(item.id)).toList();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    super.dispose();
  }
}
