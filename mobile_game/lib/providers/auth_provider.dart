import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(const AsyncValue.loading()) {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // Stub for google sign in (needs google_sign_in package in real app)
      // For now, simulate success or error if needed.
      throw UnimplementedError("Google Sign-In is not fully implemented yet.");
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInAnonymously();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
