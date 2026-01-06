import 'dart:async';
import 'dart:math' as math;

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _borrowerEmailSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownerEmailSub;

  List<Booking> get bookings =>
      _bookingMap.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Booking> get myBookings {
    final user = _currentUser;
    if (user == null) return [];
    return bookings.where((b) => _matchesUser(b, user, isOwner: false)).toList();
  }

  List<Booking> get incomingRequests {
    final user = _currentUser;
    if (user == null) return [];
    return bookings
        .where((b) =>
            _matchesUser(b, user, isOwner: true) &&
            b.status == BookingStatus.pending)
        .toList();
  }

  int get pendingRequestsCount => incomingRequests.length;

  int get pendingOwnerPaymentCount {
    final user = _currentUser;
    if (user == null) return 0;
    return bookings
        .where((b) =>
            _matchesUser(b, user, isOwner: true) &&
            b.status == BookingStatus.accepted &&
            b.paymentStatus == PaymentStatus.pending)
        .length;
  }

  void setUser(app.User? user) {
    if (user?.id == _currentUser?.id) return;
    _currentUser = user;
    _bookingMap.clear();
    _borrowerSub?.cancel();
    _ownerSub?.cancel();
    _borrowerEmailSub?.cancel();
    _ownerEmailSub?.cancel();
    _borrowerSub = null;
    _ownerSub = null;
    _borrowerEmailSub = null;
    _ownerEmailSub = null;

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

  bool _matchesUser(Booking booking, app.User user, {required bool isOwner}) {
    final id = isOwner ? booking.ownerId : booking.borrowerId;
    if (id == user.id) return true;
    final email = user.email;
    if (email.isEmpty) return false;
    final bookingEmail =
        isOwner ? booking.owner.email : booking.borrower.email;
    return bookingEmail.isNotEmpty && bookingEmail == email;
  }

  Future<void> createBookingRequest({
    required Item item,
    required app.User borrower,
    required DateTime startDate,
    required DateTime endDate,
    String? requestMessage,
  }) async {
    if (item.owner.id == borrower.id ||
        (borrower.email.isNotEmpty &&
            item.owner.email.isNotEmpty &&
            item.owner.email == borrower.email)) {
      throw StateError('You cannot book your own listing.');
    }
    final docRef = _db.collection('bookings').doc();
    final totalUnits = calculateUnits(
      startDate: startDate,
      endDate: endDate,
      priceUnit: item.priceUnit,
    );
    final total = item.price * totalUnits;
    final booking = Booking(
      id: docRef.id,
      item: item,
      borrower: borrower,
      owner: item.owner,
      startDate: startDate,
      endDate: endDate,
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.pending,
      depositAmount: item.deposit,
      rentAmount: item.price,
      currency: 'MYR',
      totalPrice: total,
      createdAt: DateTime.now(),
      requestMessage: requestMessage,
    );

    await docRef.set(booking.toJson());
  }

  Future<void> acceptRequest(String bookingId, {String? message}) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.accepted.toString().split('.').last,
      'ownerResponseMessage': message,
    });
  }

  Future<void> rejectRequest(String bookingId, {String? message}) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.rejected.toString().split('.').last,
      'ownerResponseMessage': message,
    });
  }

  Future<void> markPaymentReceived(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).update({
      'paymentStatus': PaymentStatus.paid.toString().split('.').last,
      'status': BookingStatus.pendingPickup.toString().split('.').last,
    });
    await _db.collection('items').doc(booking.itemId).update({
      'available': false,
      'expectedAvailableDate': booking.endDate,
    });
  }

  Future<void> markItemReceived(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).update({
      'status': BookingStatus.active.toString().split('.').last,
    });
  }

  Future<void> markItemReturned(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).update({
      'status': BookingStatus.completed.toString().split('.').last,
    });
    await _db.collection('items').doc(booking.itemId).update({
      'available': true,
      'expectedAvailableDate': null,
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

  static int calculateUnits({
    required DateTime startDate,
    required DateTime endDate,
    required PriceUnit priceUnit,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final diffDays = end.difference(start).inDays;
    final days = diffDays < 0 ? 0 : diffDays + 1;

    switch (priceUnit) {
      case PriceUnit.hour:
        final hours = end.difference(start).inHours;
        return hours <= 0 ? 1 : hours;
      case PriceUnit.day:
        return days;
      case PriceUnit.week:
        return math.max(1, (days / 7).ceil());
      case PriceUnit.month:
        return math.max(1, (days / 30).ceil());
      case PriceUnit.job:
        return 1;
    }
  }

  @override
  void dispose() {
    _borrowerSub?.cancel();
    _ownerSub?.cancel();
    _borrowerEmailSub?.cancel();
    _ownerEmailSub?.cancel();
    super.dispose();
  }
}
