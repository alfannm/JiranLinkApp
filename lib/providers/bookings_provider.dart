import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../data/mock_data.dart';

class BookingsProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  List<BookingRequest> _requests = [];

  BookingsProvider() {
    _bookings = MockData.mockBookings;
  }

  List<Booking> get bookings => _bookings;
  List<BookingRequest> get requests => _requests;
  
  int get pendingRequestsCount =>
      _requests.where((r) => r.status == BookingRequestStatus.pending).length;

  void createBookingRequest({
    required Item item,
    required User borrower,
    String? message,
  }) {
    final request = BookingRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      item: item,
      borrower: borrower,
      owner: item.owner,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      status: BookingRequestStatus.pending,
      totalPrice: item.price * 7,
      message: message ?? "Hi! I'd like to ${item.type.toString().split('.').last} your ${item.title}.",
      createdAt: DateTime.now(),
    );

    _requests.insert(0, request);
    notifyListeners();
  }

  void acceptRequest(String requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final request = _requests[index];
      _requests[index] = BookingRequest(
        id: request.id,
        item: request.item,
        borrower: request.borrower,
        owner: request.owner,
        startDate: request.startDate,
        endDate: request.endDate,
        status: BookingRequestStatus.accepted,
        totalPrice: request.totalPrice,
        message: request.message,
        createdAt: request.createdAt,
      );
      notifyListeners();
    }
  }

  void rejectRequest(String requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final request = _requests[index];
      _requests[index] = BookingRequest(
        id: request.id,
        item: request.item,
        borrower: request.borrower,
        owner: request.owner,
        startDate: request.startDate,
        endDate: request.endDate,
        status: BookingRequestStatus.rejected,
        totalPrice: request.totalPrice,
        message: request.message,
        createdAt: request.createdAt,
      );
      notifyListeners();
    }
  }
}
