import 'item.dart';
import 'user.dart';

enum BookingStatus { pending, active, completed, cancelled }
enum BookingRequestStatus { pending, accepted, rejected }

class Booking {
  final String id;
  final Item item;
  final User borrower;
  final User owner;
  final DateTime startDate;
  final DateTime endDate;
  final BookingStatus status;
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
      totalPrice: json['totalPrice'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class BookingRequest {
  final String id;
  final Item item;
  final User borrower;
  final User owner;
  final DateTime startDate;
  final DateTime endDate;
  final BookingRequestStatus status;
  final double totalPrice;
  final String? message;
  final DateTime createdAt;

  BookingRequest({
    required this.id,
    required this.item,
    required this.borrower,
    required this.owner,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
    this.message,
    required this.createdAt,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    return BookingRequest(
      id: json['id'],
      item: Item.fromJson(json['item']),
      borrower: User.fromJson(json['borrower']),
      owner: User.fromJson(json['owner']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: BookingRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      totalPrice: json['totalPrice'].toDouble(),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
    );
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
