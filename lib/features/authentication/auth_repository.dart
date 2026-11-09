import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// The signed-in user, as the rest of the app sees it.
///
/// Supabase's [User] exposes the id as `.id`; this wrapper keeps the
/// `.uid` name the app already uses everywhere (auth state, profiles,
/// bookings, queue) so switching auth providers touches only this file.
class DouriUser {
  const DouriUser({required this.uid, this.phone});

  factory DouriUser.fromSupabase(User user) =>
      DouriUser(uid: user.id, phone: user.phone);

  /// Supabase Auth user id. This is also the `profiles.id` the RLS
  /// policies check (`auth.uid()`), so Supabase Auth — unlike the old
  /// Firebase Auth login — matches the database identity.
  final String uid;
  final String? phone;
}

/// Phone OTP login delivered over **WhatsApp**.
///
/// The app calls Supabase Auth (`signInWithOtp` / `verifyOtp`). Supabase
/// generates and verifies the code; delivery is done by the
/// `send-whatsapp-otp` Edge Function, wired as the Auth "Send SMS" hook,
/// which sends the code through Meta's WhatsApp Cloud API. Firebase Auth
/// is no longer used for login (Firebase remains only for push via FCM).
class AuthRepository {
  AuthRepository([SupabaseClient? client])
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Stream<DouriUser?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user == null ? null : DouriUser.fromSupabase(user);
      });

  DouriUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : DouriUser.fromSupabase(user);
  }

  /// Sends a 6-digit code to the user's WhatsApp for [phoneNumber]
  /// (E.164, e.g. +2135XXXXXXXX). Throws a plain [Exception] with a
  /// readable message on failure.
  Future<void> sendOtp({required String phoneNumber}) async {
    try {
      await _client.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Verifies [smsCode] for [phoneNumber] and returns the signed-in
  /// user's id (Supabase Auth uid) on success.
  Future<String> verifyOtp({
    required String phoneNumber,
    required String smsCode,
  }) async {
    try {
      final response = await _client.auth.verifyOtp(
        phone: phoneNumber,
        token: smsCode,
        type: OtpType.sms,
      );
      final user = response.user;
      if (user == null) throw Exception('Verification failed');
      return user.id;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
