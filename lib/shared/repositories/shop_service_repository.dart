import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop_service.dart';
import '../models/queue_entry.dart';
import '../../core/services/supabase_service.dart';

class ShopServiceRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<ShopService>> listServices(String shopId) async {
    final data = await _client
        .from('shop_services')
        .select()
        .eq('barber_shop_id', shopId)
        .eq('is_active', true)
        .order('service_name');
    return (data as List).map((e) => ShopService.fromMap(e)).toList();
  }

  Future<List<ShopService>> listAllServices(String shopId) async {
    final data = await _client
        .from('shop_services')
        .select()
        .eq('barber_shop_id', shopId)
        .order('service_name');
    return (data as List).map((e) => ShopService.fromMap(e)).toList();
  }

  Future<void> addService(ShopService service) async {
    await _client.from('shop_services').insert(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    await _client.from('shop_services').delete().eq('id', serviceId);
  }

  Future<List<Review>> listReviews(String shopId) async {
    final data = await _client.from('reviews').select().eq('barber_shop_id', shopId);
    return (data as List).map((e) => Review.fromMap(e)).toList();
  }
}
