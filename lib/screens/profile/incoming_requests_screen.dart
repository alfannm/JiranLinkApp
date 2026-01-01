import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<BookingsProvider>().incomingRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No new requests'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return RequestCard(booking: requests[index]);
              },
            ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Booking booking;

  const RequestCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final provider = context.read<BookingsProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: booking.borrower.avatar != null
                    ? NetworkImage(booking.borrower.avatar!)
                    : null,
                child: booking.borrower.avatar == null
                    ? Text(booking.borrower.name[0])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.borrower.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'wants to rent ${booking.item.title}',
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Earnings',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    Text(
                      'RM${booking.totalPrice}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    provider.rejectRequest(booking.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.destructive,
                    side: const BorderSide(color: AppTheme.destructive),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    provider.acceptRequest(booking.id);
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
