import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/supabase_service.dart';

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.client
        .from('bookings')
        .select()
        .eq('barber_shop_id', widget.shopId)
        .eq('status', 'PENDING');
    setState(() {
      _bookings = (data as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  Future<void> _approve(String id) async {
    await SupabaseService.client.rpc('approve_booking', params: {'p_booking_id': id});
    await _load();
  }

  Future<void> _reject(String id) async {
    await SupabaseService.client.rpc('reject_booking', params: {'p_booking_id': id, 'p_reason': null});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
    if (_bookings.isEmpty) return Center(child: Text(l10n.empty, style: const TextStyle(color: Colors.white)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (_, i) {
        final b = _bookings[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryBackground, AppColors.primaryAccent, Colors.black]),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text('Name : ${b['customer_name']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Phone : ${b['customer_phone']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Date : ${b['booking_date']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Time : ${b['booking_time']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white),
                        onPressed: () => _approve(b['id'] as String),
                        child: Text(l10n.approve),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                        onPressed: () => _reject(b['id'] as String),
                        child: Text(l10n.reject),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
