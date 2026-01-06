import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _processing = false;

  String _formatCurrency(double value) {
    return 'RM ${value.toStringAsFixed(2)}';
  }

  Future<void> _submitPayment() async {
    if (_processing) return;
    setState(() {
      _processing = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      await context.read<BookingsProvider>().markPaymentReceived(widget.booking);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final deposit = booking.depositAmount ?? 0;
    final totalWithDeposit = booking.totalPrice + deposit;
    final dateFormat = DateFormat('MMM d, y');
    final receiptEmail = booking.borrower.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.cardBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityBanner(),
            const SizedBox(height: 16),
            _buildItemSummary(
              booking,
              '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Payment Summary'),
            const SizedBox(height: 12),
            _buildPriceSummary(
              rentAmount: booking.totalPrice,
              depositAmount: deposit,
              totalAmount: totalWithDeposit,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentMethods(),
            const SizedBox(height: 16),
            _buildSectionTitle('What Happens Next'),
            const SizedBox(height: 12),
            _buildProcessTimeline(),
            const SizedBox(height: 16),
            _buildSectionTitle('Protection For Both Parties'),
            const SizedBox(height: 12),
            _buildProtectionCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('Receipt And Notifications'),
            const SizedBox(height: 12),
            _buildReceiptCard(receiptEmail),
          ],
        ),
      ),
      bottomSheet: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total due now',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatCurrency(totalWithDeposit),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processing ? null : _submitPayment,
                  child: Text(
                    _processing
                        ? 'Processing...'
                        : 'Pay ${_formatCurrency(totalWithDeposit)}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mock payment only. No real charge will be made.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Secure payment held by JiranLink until pickup or service is confirmed.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSummary(Booking booking, String dateLabel) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                child: CachedNetworkImage(
                  imageUrl: booking.item.images.isNotEmpty
                      ? booking.item.images.first
                      : 'https://placehold.co/120x120/png',
                  width: 64,
                  height: 64,
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
              Text(
                _formatCurrency(booking.totalPrice),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.calendar_today_outlined, 'Dates', dateLabel),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.person_outline,
            'Owner',
            booking.owner.name,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedForeground),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPriceSummary({
    required double rentAmount,
    required double depositAmount,
    required double totalAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildPriceRow('Rent Amount', _formatCurrency(rentAmount)),
          if (depositAmount > 0)
            _buildPriceRow(
              'Security Deposit',
              _formatCurrency(depositAmount),
            ),
          const Divider(height: 24),
          _buildPriceRow(
            'Total due now',
            _formatCurrency(totalAmount),
            highlight: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'Funds are held and released after confirmation.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.mutedForeground)),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppTheme.primary : AppTheme.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildPaymentOption(
            value: 0,
            icon: Icons.credit_card,
            title: 'Credit or Debit Card',
            subtitle: 'Visa, MasterCard, Amex',
          ),
          if (_selectedMethod == 0) _buildSavedCardRow(),
          _buildPaymentOption(
            value: 1,
            icon: Icons.account_balance,
            title: 'Online Banking (FPX)',
            subtitle: 'Redirect to your bank to complete payment',
          ),
          _buildPaymentOption(
            value: 2,
            icon: Icons.account_balance_wallet,
            title: 'E-wallet',
            subtitle: 'Touch n Go, GrabPay, Boost',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required int value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (selected) {
                if (selected == null) return;
                setState(() {
                  _selectedMethod = selected;
                });
              },
            ),
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Widget _buildSavedCardRow() {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.credit_card, color: AppTheme.mutedForeground),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visa ending 4242',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Expires 08/27',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Default',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessTimeline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildTimelineRow(
            Icons.check_circle_outline,
            'Payment confirmed',
            'Funds are held securely until the handoff is complete.',
          ),
          _buildTimelineRow(
            Icons.notifications_active,
            'Owner notified',
            'The owner receives instant confirmation to prepare the item.',
          ),
          _buildTimelineRow(
            Icons.calendar_today,
            'Meetup or service',
            'Complete the handoff on the scheduled dates.',
          ),
          _buildTimelineRow(
            Icons.attach_money,
            'Payout released',
            'Owner receives payout after borrower confirms.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    IconData icon,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  Widget _buildProtectionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildProtectionRow(
            Icons.security,
            'Borrower protection',
            'Report issues within 24 hours for support or refund review.',
          ),
          const SizedBox(height: 12),
          _buildProtectionRow(
            Icons.verified_user,
            'Owner assurance',
            'Payment is confirmed before the handoff starts.',
          ),
          const SizedBox(height: 12),
          _buildProtectionRow(
            Icons.help_outline,
            'Dispute support',
            'JiranLink helps resolve issues fairly for both sides.',
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(String email) {
    final receiptLine = email.isNotEmpty
        ? 'Receipt will be sent to $email.'
        : 'Receipt will appear in your booking history.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.receipt, 'Receipt', receiptLine),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.notifications_none,
            'Notifications',
            'Both parties receive status updates in the app.',
          ),
        ],
      ),
    );
  }
}
