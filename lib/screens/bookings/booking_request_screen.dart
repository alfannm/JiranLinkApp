import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/user.dart' as app;
import '../../providers/bookings_provider.dart';
import '../../theme/app_theme.dart';

class BookingRequestScreen extends StatefulWidget {
  final Item item;
  final app.User borrower;

  const BookingRequestScreen({
    super.key,
    required this.item,
    required this.borrower,
  });

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  bool get _isService =>
      widget.item.type == ItemType.hire ||
      widget.item.category == ItemCategory.services ||
      widget.item.category == ItemCategory.skills;
  bool get _isOwnerBooking {
    final owner = widget.item.owner;
    final borrower = widget.borrower;
    return owner.id == borrower.id ||
        (borrower.email.isNotEmpty &&
            owner.email.isNotEmpty &&
            owner.email == borrower.email);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _durationUnits() {
    if (_startDate == null || _endDate == null) return 0;
    return BookingsProvider.calculateUnits(
      startDate: _startDate!,
      endDate: _endDate!,
      priceUnit: widget.item.priceUnit,
    );
  }

  String _priceUnitLabel() {
    switch (widget.item.priceUnit) {
      case PriceUnit.hour:
        return 'hour';
      case PriceUnit.day:
        return 'day';
      case PriceUnit.week:
        return 'week';
      case PriceUnit.month:
        return 'month';
      case PriceUnit.job:
        return 'job';
    }
  }

  String _durationLabel() {
    final units = _durationUnits();
    final unitLabel = _priceUnitLabel();
    if (units == 1) {
      return '1 $unitLabel';
    }
    return '$units ${unitLabel}s';
  }

  String _formatCurrency(double value) {
    return 'RM ${value.toStringAsFixed(2)}';
  }

  double _totalAmount() {
    if (_startDate == null || _endDate == null) return 0;
    return widget.item.price * _durationUnits();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startController.text = _dateFormat.format(picked);
      if (_endDate == null || _endDate!.isBefore(picked)) {
        _endDate = picked;
        _endController.text = _dateFormat.format(picked);
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _endController.text = _dateFormat.format(picked);
    });
  }

  Future<void> _submitRequest() async {
    if (_isOwnerBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot book your own listing.')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final message = _notesController.text.trim();
    try {
      await context.read<BookingsProvider>().createBookingRequest(
            item: widget.item,
            borrower: widget.borrower,
            startDate: _startDate!,
            endDate: _endDate!,
            requestMessage: message.isEmpty ? null : message,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOwnerBooking) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline,
                    size: 48, color: AppTheme.mutedForeground),
                const SizedBox(height: 12),
                const Text(
                  'You cannot book your own listing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final owner = widget.item.owner;
    final deposit = widget.item.deposit ?? 0;
    final totalAmount = _totalAmount();
    final totalWithDeposit = totalAmount + deposit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              _isService ? 'Service Details' : 'Rental Details',
              Icons.calendar_month,
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'Start Date',
              controller: _startController,
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'End Date',
              controller: _endController,
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(
              'Special Notes (Optional)',
              Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Add any special requests or additional information...',
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Price Summary', Icons.attach_money),
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
                    'Price per ${_priceUnitLabel()}',
                    _formatCurrency(widget.item.price),
                  ),
                  _buildPriceRow('Duration', _durationLabel()),
                  if (widget.item.deposit != null)
                    _buildPriceRow(
                      'Security Deposit',
                      _formatCurrency(deposit),
                    ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total Amount',
                    _formatCurrency(totalAmount),
                    highlight: true,
                  ),
                  if (widget.item.deposit != null)
                    _buildPriceRow(
                      'Total with Deposit',
                      _formatCurrency(totalWithDeposit),
                      highlight: true,
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    '* Payment will be processed after the owner accepts your request',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader('Request will be sent to', Icons.person_outline),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    backgroundImage:
                        owner.avatar != null ? NetworkImage(owner.avatar!) : null,
                    child: owner.avatar == null
                        ? Text(
                            owner.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          owner.district,
                          style: const TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
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
              onPressed: _submitting ? null : _submitRequest,
              child: Text(_submitting ? 'Sending...' : 'Confirm & Send Request'),
            ),
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
              imageUrl: widget.item.images.isNotEmpty
                  ? widget.item.images.first
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
                  widget.item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.category.toString().split('.').last,
                  style: const TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.getPriceLabel(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/yyyy',
        suffixIcon: const Icon(Icons.calendar_today_outlined),
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
}
