import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String district;
  final String? avatar;
  final DateTime joinDate;
  final double rating;
  final int reviewCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.district,
    this.avatar,
    required this.joinDate,
    required this.rating,
    required this.reviewCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final joinDateRaw = json['joinDate'];
    DateTime joinDate;
    if (joinDateRaw is Timestamp) {
      joinDate = joinDateRaw.toDate();
    } else if (joinDateRaw is DateTime) {
      joinDate = joinDateRaw;
    } else if (joinDateRaw is String) {
      joinDate = DateTime.tryParse(joinDateRaw) ?? DateTime.now();
    } else {
      joinDate = DateTime.now();
    }

    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      district: json['district'] ?? 'Unknown',
      avatar: json['avatar'],
      joinDate: joinDate,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return User(
      id: doc.id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      district: data['district'] ?? 'Unknown',
      avatar: data['avatar'],
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'district': district,
      'avatar': avatar,
      'joinDate': joinDate,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
