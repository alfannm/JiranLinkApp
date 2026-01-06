import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../services/location_service.dart';

// Items collection provider with filters and storage support.
class ItemsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Item> _items = [];
  String _searchQuery = '';
  ItemCategory? _selectedCategory;
  // Search radius in kilometers.
  double? _radiusFilter;
  double? _userLatitude;
  double? _userLongitude;

  final LocationService _locationService = LocationService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _itemsSub;

  // Starts listening to item changes.
  ItemsProvider() {
    _listenToItems();
  }

  // Cleans up Firestore subscriptions.
  @override
  void dispose() {
    _itemsSub?.cancel();
    super.dispose();
  }

  // Items filtered by current search and filters.
  List<Item> get items => _filteredItems();
  // All items from the backend.
  List<Item> get allItems => _items;
  // Selected category filter.
  ItemCategory? get selectedCategory => _selectedCategory;
  // Current search query.
  String get searchQuery => _searchQuery;
  // User latitude for distance filtering.
  double? get userLatitude => _userLatitude;
  // User longitude for distance filtering.
  double? get userLongitude => _userLongitude;
  // Current radius filter.
  double? get radiusFilter => _radiusFilter;

  // Detects device location and stores it for filtering.
  Future<bool> detectAndSetUserLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      _userLatitude = pos.latitude;
      _userLongitude = pos.longitude;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Updates the search query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Updates the selected category filter.
  void setCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Updates the distance filter.
  void setRadiusFilter(double? radius) {
    _radiusFilter = radius;
    notifyListeners();
  }

  // Subscribes to item updates from Firestore.
  void _listenToItems() {
    _itemsSub?.cancel();
    _itemsSub = _db
        .collection('items')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs.map(Item.fromFirestore).toList();
      notifyListeners();
    });
  }

  // Uploads images and returns download URLs.
  Future<List<String>> _uploadImages({
    required String itemId,
    required List<XFile> images,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final path = 'items/$itemId/${DateTime.now().millisecondsSinceEpoch}_$i';
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Creates a new item document and uploads images.
  Future<void> createItem({
    required Item item,
    required List<XFile> images,
  }) async {
    final docRef = _db.collection('items').doc(item.id);
    final imageUrls =
        images.isEmpty ? <String>[] : await _uploadImages(itemId: docRef.id, images: images);
    final itemData = item.toJson();
    itemData['images'] = imageUrls;
    itemData['postedDate'] = DateTime.now();
    await docRef.set(itemData);
  }

  // Updates an existing item document and merges images.
  Future<void> updateItem({
    required Item item,
    required List<XFile> newImages,
    required List<String> existingImageUrls,
  }) async {
    final docRef = _db.collection('items').doc(item.id);
    final uploadedUrls = newImages.isEmpty
        ? <String>[]
        : await _uploadImages(itemId: docRef.id, images: newImages);
    final itemData = item.toJson();
    itemData['images'] = [...existingImageUrls, ...uploadedUrls];
    await docRef.set(itemData);
  }

  // Deletes an item and attempts to remove its images.
  Future<void> deleteItem(Item item) async {
    await _db.collection('items').doc(item.id).delete();
    for (final imageUrl in item.images) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (_) {
        // Skip images that cannot be deleted.
      }
    }
  }

  // Applies search, category, and distance filters.
  List<Item> _filteredItems() {
    var filtered = List<Item>.from(_items);

    // Search filter.
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Category filter.
    if (_selectedCategory != null) {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Distance filter.
    if (_radiusFilter != null &&
        _userLatitude != null &&
        _userLongitude != null) {
      filtered = filtered.where((item) {
        final distance = calculateDistance(
          _userLatitude!,
          _userLongitude!,
          item.latitude,
          item.longitude,
        );
        return distance <= _radiusFilter!;
      }).toList();
    }

    return filtered;
  }

  // Calculates distance between two coordinates in kilometers.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Degrees to radians factor.
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    // Earth diameter in km (2 * 6371).
    return 12742 * asin(sqrt(a));
  }

  // Returns a few nearby available items.
  List<Item> getNearbyItems(String district, int limit) {
    return _items
        .where((item) => item.district == district && item.available)
        .take(limit)
        .toList();
  }

  // Returns a few available items for featured sections.
  List<Item> getFeaturedItems(int limit) {
    return _items.where((item) => item.available).take(limit).toList();
  }

  // Finds an item by id.
  Item? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
