import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/repository_providers.dart';
import '../../authentication/auth_providers.dart';
import '../../../shared/models/barber_shop.dart';

final currentShopProvider = FutureProvider<BarberShop?>((ref) async {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return null;
  return ref.read(barberShopRepositoryProvider).getShopByOwner(uid);
});
