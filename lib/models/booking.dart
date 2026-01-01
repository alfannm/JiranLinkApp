import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';
import 'user.dart';

enum BookingStatus { pending, accepted, active, completed, cancelled, rejected }
enum PaymentStatus { pending, paid, failed, refunded }

class Booking {
  final String id;
  final Item item;
  final User borrower;
  final User owner;
  final DateTime startDate;
  final DateTime endDate;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double? depositAmount;
  final double rentAmount;
  final String currency;
  final double totalPrice;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.item,
    required this.borrower,
    required this.owner,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
    this.depositAmount,
    required this.rentAmount,
    required this.currency,
    required this.totalPrice,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      item: Item.fromJson(json['item']),
      borrower: User.fromJson(json['borrower']),
      owner: User.fromJson(json['owner']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentStatus'],
      ),
      depositAmount: json['depositAmount']?.toDouble(),
      rentAmount: json['rentAmount'].toDouble(),
      currency: json['currency'],
      totalPrice: json['totalPrice'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Booking(
      id: doc.id,
      item: Item.fromJson(Map<String, dynamic>.from(data['item'] ?? {})),
      borrower: User.fromJson(Map<String, dynamic>.from(data['borrower'] ?? {})),
      owner: User.fromJson(Map<String, dynamic>.from(data['owner'] ?? {})),
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      depositAmount: (data['depositAmount'] as num?)?.toDouble(),
      rentAmount: (data['rentAmount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'MYR',
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': item.id,
      'item': item.toJson(),
      'borrowerId': borrower.id,
      'borrower': borrower.toJson(),
      'ownerId': owner.id,
      'owner': owner.toJson(),
      'startDate': startDate,
      'endDate': endDate,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'depositAmount': depositAmount,
      'rentAmount': rentAmount,
      'currency': currency,
      'totalPrice': totalPrice,
      'createdAt': createdAt,
    };
  }
}

class Message {
  final String id;
  final User from;
  final User to;
  final Item? item;
  final String lastMessage;
  final DateTime timestamp;
  final bool unread;

  Message({
    required this.id,
    required this.from,
    required this.to,
    this.item,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      from: User.fromJson(json['from']),
      to: User.fromJson(json['to']),
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
      lastMessage: json['lastMessage'],
      timestamp: DateTime.parse(json['timestamp']),
      unread: json['unread'],
    );
  }
}
