import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/auth_providers.dart';
import '../../shared/models/profile.dart';
import '../../shared/repositories/profile_repository.dart';
import '../../shared/repositories/barber_shop_repository.dart';
import '../../shared/repositories/booking_repository.dart';
import '../../shared/repositories/queue_repository.dart';
import '../../shared/repositories/shop_service_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final barberShopRepositoryProvider = Provider((ref) => BarberShopRepository());
final bookingRepositoryProvider = Provider((ref) => BookingRepository());
final shopServiceRepositoryProvider = Provider((ref) => ShopServiceRepository());
final queueRepositoryProvider = Provider((ref) => QueueRepository());

/// The signed-in user's profile, if one exists. Null for guests / new users.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return null;
  return ref.read(profileRepositoryProvider).getProfile(uid);
});
