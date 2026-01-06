import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import 'request_details_screen.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final allBookings = context.watch<BookingsProvider>().bookings;
    final requests = currentUser == null
        ? <Booking>[]
        : allBookings
            .where((booking) {
            final ownerIdMatch = booking.ownerId == currentUser.id;
            final ownerEmailMatch = currentUser.email.isNotEmpty &&
                booking.owner.email.isNotEmpty &&
                booking.owner.email == currentUser.email;
            return ownerIdMatch || ownerEmailMatch;
          })
            .toList()
      ..sort((a, b) {
        final aPending = a.status == BookingStatus.pending;
        final bPending = b.status == BookingStatus.pending;
        if (aPending != bPending) {
          return aPending ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No requests yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return RequestCard(
                  booking: requests[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RequestDetailsScreen(booking: requests[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const RequestCard({super.key, required this.booking, required this.onTap});

  Future<void> _handleDecision(BuildContext context,
      {required bool accept}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RequestDecisionDialog(accept: accept),
    );
    if (result == null) return;

    final message = result.isEmpty ? null : result;
    final provider = context.read<BookingsProvider>();
    if (accept) {
      await provider.acceptRequest(booking.id, message: message);
    } else {
      await provider.rejectRequest(booking.id, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final statusColor = _getStatusColor(booking.status);
    final needsAttention = booking.status == BookingStatus.pending ||
        (booking.status == BookingStatus.accepted &&
            booking.paymentStatus == PaymentStatus.pending);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Stack(
          children: [
            Container(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
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
                  if ((booking.requestMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Notes',
                      booking.requestMessage!,
                    ),
                  ],
                  if ((booking.ownerResponseMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Your Response', booking.ownerResponseMessage!),
                  ],
                  if (booking.status == BookingStatus.pending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _handleDecision(context, accept: false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.destructive,
                              side:
                                  const BorderSide(color: AppTheme.destructive),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _handleDecision(context, accept: true);
                            },
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (needsAttention)
              const Positioned(
                top: 10,
                right: 10,
                child: _AttentionDot(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
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

class _RequestDecisionDialog extends StatefulWidget {
  final bool accept;

  const _RequestDecisionDialog({required this.accept});

  @override
  State<_RequestDecisionDialog> createState() => _RequestDecisionDialogState();
}

class _RequestDecisionDialogState extends State<_RequestDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.accept ? 'Accept Request' : 'Decline Request'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText:
                widget.accept ? 'Add optional message...' : 'Message to borrower',
            labelStyle: const TextStyle(color: AppTheme.mutedForeground),
            hintText:
                widget.accept ? 'Optional message' : 'Please provide a reason',
          ),
          validator: widget.accept
              ? null
              : (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _AttentionDot extends StatelessWidget {
  const _AttentionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppTheme.destructive,
        shape: BoxShape.circle,
      ),
    );
  }
}
