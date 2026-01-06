import 'package:cloud_firestore/cloud_firestore.dart';
import 'item.dart';
import 'user.dart';

// Status values for a booking.
enum BookingStatus {
  pending,
  accepted,
  pendingPickup,
  active,
  completed,
  cancelled,
  rejected
}
// Status values for payments.
enum PaymentStatus { pending, paid, failed, refunded }

// Booking data model.
class Booking {
  final String id;
  final Item item;
  final String itemId;
  final User borrower;
  final String borrowerId;
  final User owner;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double? depositAmount;
  final double rentAmount;
  final String currency;
  final double totalPrice;
  final DateTime createdAt;
  final String? requestMessage;
  final String? ownerResponseMessage;

  // Creates a booking instance.
  Booking({
    required this.id,
    required this.item,
    String? itemId,
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
    this.requestMessage,
    this.ownerResponseMessage,
    String? borrowerId,
    String? ownerId,
  })  : itemId = itemId ?? item.id,
        borrowerId = borrowerId ?? borrower.id,
        ownerId = ownerId ?? owner.id;

  // Creates a booking from a JSON map.
  factory Booking.fromJson(Map<String, dynamic> json) {
    final item = Item.fromJson(json['item']);
    return Booking(
      id: json['id'],
      item: item,
      itemId: json['itemId'] ?? item.id,
      borrower: User.fromJson(json['borrower']),
      borrowerId: json['borrowerId'],
      owner: User.fromJson(json['owner']),
      ownerId: json['ownerId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      depositAmount: json['depositAmount']?.toDouble(),
      rentAmount: json['rentAmount'].toDouble(),
      currency: json['currency'],
      totalPrice: json['totalPrice'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      requestMessage: json['requestMessage'],
      ownerResponseMessage: json['ownerResponseMessage'],
    );
  }

  // Creates a booking from a Firestore document.
  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final item = Item.fromJson(Map<String, dynamic>.from(data['item'] ?? {}));
    return Booking(
      id: doc.id,
      item: item,
      itemId: data['itemId'] ?? item.id,
      borrower: User.fromJson(Map<String, dynamic>.from(data['borrower'] ?? {})),
      borrowerId: data['borrowerId'],
      owner: User.fromJson(Map<String, dynamic>.from(data['owner'] ?? {})),
      ownerId: data['ownerId'],
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
      requestMessage: data['requestMessage'],
      ownerResponseMessage: data['ownerResponseMessage'],
    );
  }

  // Converts the booking to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'item': item.toJson(),
      'borrowerId': borrowerId,
      'borrower': borrower.toJson(),
      'ownerId': ownerId,
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
      'requestMessage': requestMessage,
      'ownerResponseMessage': ownerResponseMessage,
    };
  }
}

// Display helpers for booking status and actions.
extension BookingDisplay on Booking {
  // True when the booking is for a service.
  bool get isServiceBooking =>
      item.type == ItemType.hire ||
      item.category == ItemCategory.services ||
      item.category == ItemCategory.skills;

  // User-facing status label.
  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.pendingPickup:
        return isServiceBooking ? 'Pending Session' : 'Pending Pickup';
      case BookingStatus.active:
        return isServiceBooking ? 'Service Received' : 'Item Received';
      case BookingStatus.completed:
        return isServiceBooking ? 'Service Completed' : 'Item Returned';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  // Label for the receive action.
  String get receiveActionLabel =>
      isServiceBooking ? 'Service Received' : 'Item Received';

  // Label for the return action.
  String get returnActionLabel =>
      isServiceBooking ? 'Service Completed' : 'Item Returned';
}
