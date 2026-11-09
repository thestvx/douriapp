import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../authentication/auth_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = ref.read(authStateProvider).value?.uid ?? 'test_customer';
    setState(() => _submitting = true);
    try {
      await ref.read(bookingRepositoryProvider).createBooking({
        'customer_id': uid,
        'barber_shop_id': widget.shopId,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'booking_date': _date.toIso8601String().substring(0, 10),
        'booking_time': _time.format(context),
        'status': 'PENDING',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booked successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white)),
        backgroundColor: AppColors.primaryBackground,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Let's the\njourney begin!", style: TextStyle(color: Colors.white70, fontSize: 25, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(color: AppColors.cardMauve, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Icon(Icons.content_cut, size: 80, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(filled: true, fillColor: Colors.white, labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(filled: true, fillColor: Colors.white, labelText: 'Phone')),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardMauve, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('Set a Date', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime(2101));
                        if (picked != null) setState(() => _date = picked);
                      }, icon: const Icon(Icons.calendar_month, color: Colors.white, size: 30)),
                      const SizedBox(width: 10),
                      Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.cardMauve, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('Set a Time', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      }, icon: const Icon(Icons.alarm, color: Colors.white, size: 30)),
                      const SizedBox(width: 10),
                      Text(_time.format(context), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(10)),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? l10n.loading : 'BOOK NOW', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
