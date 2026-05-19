import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  FutureOr<User?> build() {
    // Listen to Firebase Auth state changes
    final sub = _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });

    ref.onDispose(() {
      sub.cancel();
    });

    // Initial state
    return _auth.currentUser;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Handle user cancellation gracefully
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Fallback delay to allow error UI to present before reverting to previous state if desired
      await Future.delayed(const Duration(seconds: 2));
      state = AsyncValue.data(_auth.currentUser);
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await Future.delayed(const Duration(seconds: 2));
      state = AsyncValue.data(_auth.currentUser);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await Future.wait([
        _auth.signOut(),
        if (await _googleSignIn.isSignedIn()) _googleSignIn.signOut(),
      ]);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await Future.delayed(const Duration(seconds: 2));
      state = AsyncValue.data(_auth.currentUser);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
