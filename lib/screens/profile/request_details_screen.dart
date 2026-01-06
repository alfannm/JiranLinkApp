import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/app_theme.dart';

class RequestDetailsScreen extends StatelessWidget {
  final Booking booking;

  const RequestDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final statusColor = _getStatusColor(booking.status);
    final deposit = booking.depositAmount ?? 0;
    final totalWithDeposit = booking.totalPrice + deposit;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isOwner = currentUser != null &&
        (booking.ownerId == currentUser.id ||
            (currentUser.email.isNotEmpty &&
                booking.owner.email.isNotEmpty &&
                booking.owner.email == currentUser.email));
    final isPaymentPending = isOwner &&
        booking.status == BookingStatus.accepted &&
        booking.paymentStatus == PaymentStatus.pending;
    final canConfirmReturned =
        booking.status == BookingStatus.active && isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemCard(),
            const SizedBox(height: 16),
            _buildStatusChip(statusColor),
            if (isPaymentPending) ...[
              const SizedBox(height: 12),
              _buildPaymentPendingCard(),
            ],
            const SizedBox(height: 16),
            const Text(
              'Borrower',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildBorrowerCard(),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Dates',
              '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
            ),
            if ((booking.requestMessage ?? '').isNotEmpty)
              _buildInfoRow('Notes', booking.requestMessage!),
            if ((booking.ownerResponseMessage ?? '').isNotEmpty)
              _buildInfoRow('Your Response', booking.ownerResponseMessage!),
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
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: canConfirmReturned ? _buildReturnAction(context) : null,
    );
  }

  Widget _buildReturnAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              try {
                await context
                    .read<BookingsProvider>()
                    .markItemReturned(booking);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${booking.returnActionLabel} recorded.'),
                  ),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: Text(booking.returnActionLabel),
          ),
        ),
      ),
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

  Widget _buildBorrowerCard() {
    final borrower = booking.borrower;
    final fallbackLetter =
        borrower.name.isNotEmpty ? borrower.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                borrower.avatar != null ? NetworkImage(borrower.avatar!) : null,
            child: borrower.avatar == null ? Text(fallbackLetter) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borrower.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  borrower.district,
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

  Widget _buildStatusChip(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        booking.statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaymentPendingCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, color: AppTheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment pending',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Waiting for borrower to complete payment. You will be notified once it is confirmed.',
                  style: TextStyle(
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
      case BookingStatus.pendingPickup:
        return Colors.amber;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.redAccent;
    }
  }
}
