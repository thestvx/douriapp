import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../../core/services/supabase_service.dart';

class BookingRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<Booking>> getCustomerBookings(String customerId) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('customer_id', customerId)
        .order('booking_date', ascending: false);
    return (data as List).map((e) => Booking.fromMap(e)).toList();
  }

  Future<List<Booking>> getShopBookings(String shopId) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('barber_shop_id', shopId)
        .order('booking_date');
    return (data as List).map((e) => Booking.fromMap(e)).toList();
  }

  /// Inserts a booking and returns the created row. New bookings are
  /// always PENDING — the queue number is assigned only by
  /// `approve_booking` when the barber accepts.
  Future<Booking> createBooking(Map<String, dynamic> data) async {
    final row = await _client.from('bookings').insert(data).select().single();
    return Booking.fromMap(row as Map<String, dynamic>);
  }

  Future<Booking?> getBooking(String id) async {
    final data = await _client.from('bookings').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Booking.fromMap(data as Map<String, dynamic>);
  }

  /// A customer may cancel their own booking. The queue entry (if any)
  /// is left for the barber-side flow; the booking status is the source
  /// of truth for the customer.
  Future<void> cancelBooking(String id) async {
    await _client.from('bookings').update({'status': 'CANCELLED'}).eq('id', id);
  }

  /// Find a booking by its assigned queue number (today's bookings first).
  Future<Booking?> getBookingByQueueNumber(int queueNumber) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('queue_number', queueNumber)
        .order('booking_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return Booking.fromMap(data as Map<String, dynamic>);
  }

  /// Times already booked for a shop on a given date (real availability).
  Future<List<String>> bookedTimes(String shopId, String dateIso) async {
    final data = await _client
        .from('bookings')
        .select('booking_time')
        .eq('barber_shop_id', shopId)
        .eq('booking_date', dateIso)
        .neq('status', 'CANCELLED')
        .neq('status', 'REJECTED');
    return (data as List).map((e) => (e['booking_time'] ?? '') as String).toList();
  }

  Stream<List<Booking>> watchCustomerBookings(String customerId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .map((rows) => rows.map(Booking.fromMap).toList());
  }

  Stream<List<Booking>> watchShopBookings(String shopId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('barber_shop_id', shopId)
        .map((rows) => rows.map(Booking.fromMap).toList());
  }
}
