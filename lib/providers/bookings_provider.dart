import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/item.dart';
import '../models/user.dart' as app;

class BookingsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  app.User? _currentUser;
  final Map<String, Booking> _bookingMap = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _borrowerSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownerSub;

  List<Booking> get bookings =>
      _bookingMap.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Booking> get myBookings {
    final user = _currentUser;
    if (user == null) return [];
    return bookings.where((b) => b.borrower.id == user.id).toList();
  }

  List<Booking> get incomingRequests {
    final user = _currentUser;
    if (user == null) return [];
    return bookings
        .where((b) => b.owner.id == user.id && b.status == BookingStatus.pending)
        .toList();
  }

  int get pendingRequestsCount => incomingRequests.length;

  void setUser(app.User? user) {
    if (user?.id == _currentUser?.id) return;
    _currentUser = user;
    _bookingMap.clear();
    _borrowerSub?.cancel();
    _ownerSub?.cancel();
    _borrowerSub = null;
    _ownerSub = null;

    if (_currentUser == null) {
      notifyListeners();
      return;
    }

    _borrowerSub = _db
        .collection('bookings')
        .where('borrowerId', isEqualTo: _currentUser!.id)
        .snapshots()
        .listen(_mergeBookings);

    _ownerSub = _db
        .collection('bookings')
        .where('ownerId', isEqualTo: _currentUser!.id)
        .snapshots()
        .listen(_mergeBookings);
  }

  void _mergeBookings(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final doc in snapshot.docs) {
      _bookingMap[doc.id] = Booking.fromFirestore(doc);
    }
    notifyListeners();
  }

  Future<void> createBookingRequest({
    required Item item,
    required app.User borrower,
    String? message,
  }) async {
    final docRef = _db.collection('bookings').doc();
    final totalDays = _estimateTotalDays(item);
    final total = item.price * totalDays;
    final booking = Booking(
      id: docRef.id,
      item: item,
      borrower: borrower,
      owner: item.owner,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: totalDays)),
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.pending,
      depositAmount: item.deposit,
      rentAmount: item.price,
      currency: 'MYR',
      totalPrice: total,
      createdAt: DateTime.now(),
    );

    final data = booking.toJson();
    data['requestMessage'] = message;

    await docRef.set(data);
  }

  Future<void> acceptRequest(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.accepted.toString().split('.').last,
    });
  }

  Future<void> rejectRequest(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.rejected.toString().split('.').last,
    });
  }

  Future<void> markPaymentReceived(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'paymentStatus': PaymentStatus.paid.toString().split('.').last,
      'status': BookingStatus.active.toString().split('.').last,
    });
  }

  Future<void> completeBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.completed.toString().split('.').last,
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.cancelled.toString().split('.').last,
    });
  }

  int _estimateTotalDays(Item item) {
    switch (item.priceUnit) {
      case PriceUnit.hour:
        return 1;
      case PriceUnit.day:
        return 7;
      case PriceUnit.week:
        return 7;
      case PriceUnit.month:
        return 30;
      case PriceUnit.job:
        return 1;
    }
  }

  @override
  void dispose() {
    _borrowerSub?.cancel();
    _ownerSub?.cancel();
    super.dispose();
  }
}
