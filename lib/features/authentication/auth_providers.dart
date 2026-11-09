import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<DouriUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
