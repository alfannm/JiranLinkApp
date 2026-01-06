import 'package:cloud_firestore/cloud_firestore.dart';

// User profile data.
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String district;
  final String? avatar;
  final DateTime joinDate;

  // Creates a user profile instance.
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.district,
    this.avatar,
    required this.joinDate,
  });

  // Creates a user from a JSON map.
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
    );
  }

  // Creates a user from a Firestore document.
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
    );
  }

  // Converts the user to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'district': district,
      'avatar': avatar,
      'joinDate': joinDate,
    };
  }
}
