import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/repository_providers.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/queue_entry.dart';
import '../../../shared/models/shop_service.dart';

final shopsProvider = FutureProvider<List<BarberShop>>((ref) async {
  return ref.read(barberShopRepositoryProvider).listShops();
});

/// One shop by id (details / booking / confirmation / queue screens).
final shopByIdProvider = FutureProvider.family<BarberShop?, String>((ref, shopId) async {
  return ref.read(barberShopRepositoryProvider).getShop(shopId);
});

/// Active services of one shop.
final shopServicesProvider = FutureProvider.family<List<ShopService>, String>((ref, shopId) async {
  return ref.read(shopServiceRepositoryProvider).listServices(shopId);
});

/// Real average rating from the reviews table, or null when the shop has
/// no reviews yet. Never invents a rating.
final shopRatingProvider =
    FutureProvider.family<({double rating, int count})?, String>((ref, shopId) async {
  final reviews = await ref.read(shopServiceRepositoryProvider).listReviews(shopId);
  if (reviews.isEmpty) return null;
  final total = reviews.map((r) => r.rating).reduce((a, b) => a + b);
  return (rating: total / reviews.length, count: reviews.length);
});

/// Live stream of one customer's bookings (Supabase Realtime).
final customerBookingsProvider =
    StreamProvider.family<List<Booking>, String>((ref, uid) {
  return ref.read(bookingRepositoryProvider).watchCustomerBookings(uid);
});
