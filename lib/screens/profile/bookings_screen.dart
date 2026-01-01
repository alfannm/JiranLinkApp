import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsProvider>().myBookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('No bookings found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return BookingCard(
                  booking: bookings[index],
                  onPay: () {
                    context
                        .read<BookingsProvider>()
                        .markPaymentReceived(bookings[index].id);
                  },
                );
              },
            ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onPay;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final dateFormat = DateFormat('MMM d, y');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  booking.item.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'RM${booking.totalPrice}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
              if (booking.status == BookingStatus.accepted &&
                  booking.paymentStatus == PaymentStatus.pending)
                ElevatedButton(
                  onPressed: onPay,
                  child: const Text('Pay Now'),
                )
              else
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppTheme.mutedForeground),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.active:
        return Colors.blue;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.teal;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.redAccent;
    }
  }
}
