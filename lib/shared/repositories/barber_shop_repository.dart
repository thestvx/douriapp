import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/barber_shop.dart';
import '../../core/services/supabase_service.dart';

class BarberShopRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<BarberShop>> listShops() async {
    final data = await _client.from('barber_shops').select().order('created_at');
    return (data as List).map((e) => BarberShop.fromMap(e)).toList();
  }

  Future<BarberShop?> getShop(String id) async {
    final data = await _client.from('barber_shops').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return BarberShop.fromMap(data);
  }

  /// The owner's shop. Takes the oldest row instead of `maybeSingle()`:
  /// an owner can end up with two shop rows (signup wizard shop +
  /// role-screen placeholder shop), and `maybeSingle()` throws in that
  /// case — which used to crash the whole barber dashboard with a
  /// generic "action failed" error.
  Future<BarberShop?> getShopByOwner(String ownerId) async {
    final data = await _client
        .from('barber_shops')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true)
        .limit(1);
    final list = data as List;
    if (list.isEmpty) return null;
    return BarberShop.fromMap(list.first);
  }

  Future<void> upsertShop(Map<String, dynamic> data) async {
    await _client.from('barber_shops').upsert(data);
  }
}
