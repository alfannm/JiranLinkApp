import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/app_theme.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final deposit = booking.depositAmount ?? 0;
    final totalWithDeposit = booking.totalPrice + deposit;
    final statusColor = _getStatusColor(booking.status);
    final shouldPay = booking.status == BookingStatus.accepted &&
        booking.paymentStatus == PaymentStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemCard(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                booking.status.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Dates',
              '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
            ),
            if ((booking.requestMessage ?? '').isNotEmpty)
              _buildInfoRow('Notes', booking.requestMessage!),
            if ((booking.ownerResponseMessage ?? '').isNotEmpty)
              _buildInfoRow('Owner Message', booking.ownerResponseMessage!),
            const SizedBox(height: 24),
            const Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Rent Amount',
                    'RM ${booking.totalPrice.toStringAsFixed(2)}',
                  ),
                  if (booking.depositAmount != null)
                    _buildPriceRow(
                      'Security Deposit',
                      'RM ${deposit.toStringAsFixed(2)}',
                    ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total with Deposit',
                    'RM ${totalWithDeposit.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                  if (booking.status == BookingStatus.pending)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '* Payment will be processed after the owner accepts your request',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: shouldPay
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context
                          .read<BookingsProvider>()
                          .markPaymentReceived(booking.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment completed.')),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Proceed to Payment'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildItemCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: booking.item.images.isNotEmpty
                  ? booking.item.images.first
                  : 'https://placehold.co/120x120/png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.item.category.toString().split('.').last,
                  style: const TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool highlight = false}) {
    final valueStyle = TextStyle(
      color: highlight ? AppTheme.primary : AppTheme.foreground,
      fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.mutedForeground),
          ),
          Text(value, style: valueStyle),
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
