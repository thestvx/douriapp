import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/supabase_service.dart';

class QueueManagementScreen extends ConsumerStatefulWidget {
  const QueueManagementScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends ConsumerState<QueueManagementScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await SupabaseService.client
        .from('queue_entries')
        .select('*, bookings(customer_name, booking_time)')
        .order('queue_number');
    // filter by shop via daily queue not included; keep simple for now
    setState(() {
      _entries = (data as List).cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  Future<void> _next() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await SupabaseService.client.rpc('advance_queue', params: {
      'p_shop_id': widget.shopId,
      'p_date': today,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.queueManagement)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(l10n.nextCustomer),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (_, i) {
                final e = _entries[i];
                final booking = e['bookings'] as Map<String, dynamic>?;
                return ListTile(
                  leading: CircleAvatar(child: Text('${e['queue_number']}')),
                  title: Text(booking?['customer_name'] ?? ''),
                  subtitle: Text(e['status'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
