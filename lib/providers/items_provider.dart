import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../data/mock_data.dart';
import 'dart:math' show cos, sqrt, asin;
import '../services/location_service.dart';

class ItemsProvider extends ChangeNotifier {
  List<Item> _items = [];
  String _searchQuery = '';
  ItemCategory? _selectedCategory;
  double? _radiusFilter; // in kilometers
  double? _userLatitude;
  double? _userLongitude;

  final LocationService _locationService = LocationService();

  ItemsProvider() {
    _items = MockData.mockItems;
  }

  List<Item> get items => _filteredItems();
  List<Item> get allItems => _items;
  List<Item> get selectedCategoryItems => _items; // Placeholder if needed
  ItemCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  double? get radiusFilter => _radiusFilter;

  /// Ask for permission + fetch device location, then store it.
  /// Returns true if a location was obtained.
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(ItemCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    notifyListeners();
  }

  void setRadiusFilter(double? radius) {
    _radiusFilter = radius;
    notifyListeners();
  }

  List<Item> _filteredItems() {
    var filtered = _items.where((item) => item.available).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Filter by radius
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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m away';
    } else {
      return '${km.toStringAsFixed(1)}km away';
    }
  }

  List<Item> getNearbyItems(String district, int limit) {
    return _items
        .where((item) => item.district == district && item.available)
        .take(limit)
        .toList();
  }

  List<Item> getFeaturedItems(int limit) {
    return _items.where((item) => item.available).take(limit).toList();
  }

  Item? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  void addItem(Item item) {
    _items.add(item);
    notifyListeners();
  }
}
