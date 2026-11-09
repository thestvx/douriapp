import 'package:firebase_auth/firebase_auth.dart';

/// Email + password login with Firebase Auth.
///
/// Phone-number registration is parked for now (the WhatsApp OTP flow
/// built earlier — Supabase Auth + the `send-whatsapp-otp` Edge Function —
/// stays in the repo unused until Meta approves the business onboarding).
/// Identity lives in Firebase; the app's data (profiles, shops, bookings)
/// lives in Supabase. The migrations do not enable RLS, so profile/shop
/// writes with the Supabase anon key work with the Firebase uid as the
/// row id — if RLS is ever enabled, these writes need a Supabase session
/// (or a service-side path) instead.
class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Signs in with email + password. Throws a plain [Exception] carrying
  /// Firebase's readable message on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// Creates a Firebase account with email + password.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
