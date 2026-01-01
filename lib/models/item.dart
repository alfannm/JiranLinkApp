import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

enum ItemCategory { tools, appliances, skills, services, others }
enum ItemType { rent, borrow, hire }
enum ItemCondition { newItem, likeNew, good, fair }
enum PriceUnit { hour, day, week, month, job }

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
  final String address;
  final double latitude;
  final double longitude;
  final bool available;
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
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.available,
    this.condition,
    required this.postedDate,
    required this.views,
    this.rating,
    this.reviewCount,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: ItemCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      type: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      price: json['price'].toDouble(),
      deposit: json['deposit']?.toDouble(),
      priceUnit: PriceUnit.values.firstWhere(
        (e) => e.toString().split('.').last == json['priceUnit'],
      ),
      images: List<String>.from(json['images']),
      owner: User.fromJson(json['owner']),
      district: json['district'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      available: json['available'],
      condition: json['condition'] != null
          ? ItemCondition.values.firstWhere(
              (e) => e.toString().split('.').last == json['condition'],
            )
          : null,
      postedDate: DateTime.parse(json['postedDate']),
      views: json['views'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
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
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      available: data['available'] ?? true,
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
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'available': available,
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
