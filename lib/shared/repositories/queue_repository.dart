import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/queue_entry.dart';
import '../../core/services/supabase_service.dart';

/// Read access to the existing `daily_queues` and `queue_entries` tables,
/// plus realtime streams. No schema changes, no fake data.
class QueueRepository {
  SupabaseClient get _client => SupabaseService.client;

  static String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

  /// Today's queue row for a shop, if the barber has started the day.
  Future<Map<String, dynamic>?> getTodayQueue(String shopId) async {
    final data = await _client
        .from('daily_queues')
        .select()
        .eq('barber_shop_id', shopId)
        .eq('queue_date', todayIso())
        .maybeSingle();
    return data as Map<String, dynamic>?;
  }

  Future<List<QueueEntry>> listTodayEntries(String shopId) async {
    final queue = await getTodayQueue(shopId);
    if (queue == null) return [];
    final data = await _client
        .from('queue_entries')
        .select('*, bookings(customer_name, booking_time)')
        .eq('daily_queue_id', queue['id'] as String)
        .order('queue_number');
    return (data as List).map((e) => QueueEntry.fromMap(e)).toList();
  }

  /// Live stream of today's queue entries for a shop (Supabase Realtime).
  Stream<List<QueueEntry>> watchTodayEntries(String shopId) async* {
    final queue = await getTodayQueue(shopId);
    if (queue == null) {
      yield [];
      return;
    }
    final queueId = queue['id'] as String;
    yield* _client
        .from('queue_entries')
        .stream(primaryKey: ['id'])
        .eq('daily_queue_id', queueId)
        .order('queue_number')
        .map((rows) => rows.map(QueueEntry.fromMap).toList());
  }

  /// The customer's queue entry for a booking (live). Returns null when
  /// the booking has not been accepted yet (no queue number assigned).
  Future<QueueEntry?> getEntryForBooking(String bookingId) async {
    final data = await _client
        .from('queue_entries')
        .select('*, bookings(customer_name, booking_time)')
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (data == null) return null;
    return QueueEntry.fromMap(data as Map<String, dynamic>);
  }

  Stream<QueueEntry?> watchEntryForBooking(String bookingId) {
    return _client
        .from('queue_entries')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .map((rows) => rows.isEmpty ? null : QueueEntry.fromMap(rows.first));
  }

  /// How many WAITING entries are ahead of [queueNumber] today.
  Future<int> countAhead(String shopId, int queueNumber) async {
    final entries = await listTodayEntries(shopId);
    return entries.where((e) => e.queueNumber < queueNumber && (e.isWaiting || e.isApproaching)).length;
  }

  /// Start (or re-open) today's daily queue for a shop.
  Future<void> startTodayQueue(String shopId) async {
    await _client.from('daily_queues').upsert({
      'barber_shop_id': shopId,
      'queue_date': todayIso(),
      'queue_status': 'ACTIVE',
      'started_at': DateTime.now().toIso8601String(),
    }, onConflict: 'barber_shop_id,queue_date');
  }

  /// End today's queue.
  Future<void> endTodayQueue(String shopId) async {
    await _client
        .from('daily_queues')
        .update({'queue_status': 'ENDED', 'ended_at': DateTime.now().toIso8601String()})
        .eq('barber_shop_id', shopId)
        .eq('queue_date', todayIso());
  }
}
