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
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      district: json['district'],
      avatar: json['avatar'],
      joinDate: DateTime.parse(json['joinDate']),
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
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
      'joinDate': joinDate.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}
