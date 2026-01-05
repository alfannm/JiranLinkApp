import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

enum ItemCategory { tools, appliances, skills, services, others }
enum ItemType { rent, borrow, hire }
enum ItemCondition { newItem, likeNew, good, fair }
enum PriceUnit { hour, day, week, month, job }

DateTime? _parseOptionalDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class Item {
  final String id;
  final String title;
  final String description;
  final ItemCategory category;
  final ItemType type;
  final double price;
  final double? deposit;
  final PriceUnit priceUnit;
  final List<String> images;
  final User owner;
  final String district;
  final String state;
  final String address;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool available;
  final DateTime? expectedAvailableDate;
  final ItemCondition? condition;
  final DateTime postedDate;
  final int views;
  final double? rating;
  final int? reviewCount;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.price,
    this.deposit,
    required this.priceUnit,
    required this.images,
    required this.owner,
    required this.district,
    required this.state,
    required this.address,
    this.landmark,
    required this.latitude,
    required this.longitude,
    required this.available,
    this.expectedAvailableDate,
    this.condition,
    required this.postedDate,
    required this.views,
    this.rating,
    this.reviewCount,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final postedRaw = json['postedDate'];
    DateTime postedDate;
    if (postedRaw is Timestamp) {
      postedDate = postedRaw.toDate();
    } else if (postedRaw is DateTime) {
      postedDate = postedRaw;
    } else if (postedRaw is String) {
      postedDate = DateTime.tryParse(postedRaw) ?? DateTime.now();
    } else {
      postedDate = DateTime.now();
    }

    return Item(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ItemCategory.others,
      ),
      type: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ItemType.rent,
      ),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      deposit: (json['deposit'] as num?)?.toDouble(),
      priceUnit: PriceUnit.values.firstWhere(
        (e) => e.toString().split('.').last == json['priceUnit'],
        orElse: () => PriceUnit.day,
      ),
      images: List<String>.from(json['images'] ?? const []),
      owner: User.fromJson(Map<String, dynamic>.from(json['owner'] ?? {})),
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      available: json['available'] ?? true,
      expectedAvailableDate: _parseOptionalDate(json['expectedAvailableDate']),
      condition: json['condition'] != null
          ? ItemCondition.values.firstWhere(
              (e) => e.toString().split('.').last == json['condition'],
              orElse: () => ItemCondition.good,
            )
          : null,
      postedDate: postedDate,
      views: (json['views'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
    );
  }

  factory Item.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => ItemCategory.others,
      ),
      type: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ItemType.rent,
      ),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      deposit: (data['deposit'] as num?)?.toDouble(),
      priceUnit: PriceUnit.values.firstWhere(
        (e) => e.toString().split('.').last == data['priceUnit'],
        orElse: () => PriceUnit.day,
      ),
      images: List<String>.from(data['images'] ?? []),
      owner: User.fromJson(Map<String, dynamic>.from(data['owner'] ?? {})),
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      address: data['address'] ?? '',
      landmark: data['landmark'],
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      available: data['available'] ?? true,
      expectedAvailableDate: _parseOptionalDate(data['expectedAvailableDate']),
      condition: data['condition'] != null
          ? ItemCondition.values.firstWhere(
              (e) => e.toString().split('.').last == data['condition'],
              orElse: () => ItemCondition.good,
            )
          : null,
      postedDate:
          (data['postedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      views: (data['views'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: (data['reviewCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'type': type.toString().split('.').last,
      'price': price,
      'deposit': deposit,
      'priceUnit': priceUnit.toString().split('.').last,
      'images': images,
      'owner': owner.toJson(),
      'district': district,
      'state': state,
      'address': address,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'available': available,
      'expectedAvailableDate': expectedAvailableDate,
      'condition': condition?.toString().split('.').last,
      'postedDate': postedDate,
      'views': views,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  String getPriceLabel() {
    return 'RM${price.toStringAsFixed(0)}/${priceUnit.toString().split('.').last}';
  }
}
