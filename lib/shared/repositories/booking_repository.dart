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

  Future<void> createBooking(Map<String, dynamic> data) async {
    await _client.from('bookings').insert(data);
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
