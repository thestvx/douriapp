import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/barber_shop.dart';
import '../../../core/services/repository_providers.dart';

final shopsProvider = FutureProvider<List<BarberShop>>((ref) async {
  return ref.read(barberShopRepositoryProvider).listShops();
});
