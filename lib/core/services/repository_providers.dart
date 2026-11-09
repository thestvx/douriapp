import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/repositories/profile_repository.dart';
import '../../shared/repositories/barber_shop_repository.dart';
import '../../shared/repositories/booking_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final barberShopRepositoryProvider = Provider((ref) => BarberShopRepository());
final bookingRepositoryProvider = Provider((ref) => BookingRepository());
