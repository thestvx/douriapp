import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../../core/services/supabase_service.dart';

class ProfileRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<void> upsertProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }
}
