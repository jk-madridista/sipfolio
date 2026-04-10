import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/auth_service.dart';
import '../services/user_profile_repository.dart';

part 'auth_notifier.g.dart';

/// Tracks the current Firebase [User] (or null when signed out).
///
/// Exposes sign-in / sign-out actions that update state with loading and
/// error handling. On successful sign-in the user's Firestore [UserProfile]
/// document is created if it does not yet exist.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  StreamSubscription<User?>? _authSub;

  @override
  Future<User?> build() async {
    final authService = ref.read(authServiceProvider);

    // Cancel any previous subscription when the provider is rebuilt.
    ref.onDispose(() => _authSub?.cancel());

    // We need to complete the future with the first emitted value, then keep
    // watching the stream for subsequent changes.
    final completer = Completer<User?>();

    _authSub = authService.authStateChanges.listen(
      (user) {
        if (!completer.isCompleted) {
          completer.complete(user);
        } else {
          // Subsequent auth state changes (e.g. token refresh, sign-out).
          state = AsyncData(user);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        } else {
          state = AsyncError(error, stack);
        }
      },
    );

    return completer.future;
  }

  /// Signs in with Google and creates a Firestore [UserProfile] if needed.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential =
          await ref.read(authServiceProvider).signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        await ref
            .read(userProfileRepositoryProvider)
            .ensureUserProfile(user);
      }
      return user;
    });
  }

  /// Signs in with email/password and creates a Firestore [UserProfile] if needed.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(authServiceProvider)
          .signInWithEmail(email, password);
      final user = credential.user;
      if (user != null) {
        await ref
            .read(userProfileRepositoryProvider)
            .ensureUserProfile(user);
      }
      return user;
    });
  }

  /// Signs out from Firebase and Google Sign-In.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
      return null;
    });
  }
}
