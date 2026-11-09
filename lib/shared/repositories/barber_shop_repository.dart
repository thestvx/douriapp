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

  Future<BarberShop?> getShopByOwner(String ownerId) async {
    final data = await _client
        .from('barber_shops')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    if (data == null) return null;
    return BarberShop.fromMap(data);
  }

  Future<void> upsertShop(Map<String, dynamic> data) async {
    await _client.from('barber_shops').upsert(data);
  }
}
