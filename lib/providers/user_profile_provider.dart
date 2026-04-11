import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../providers/auth_notifier.dart';
import '../services/user_profile_repository.dart';

/// Streams the currently authenticated user's [UserProfile] from Firestore.
///
/// Emits null while auth is loading, when the user is signed out, or if no
/// profile document exists yet. Automatically re-subscribes whenever the
/// authenticated user changes.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authNotifierProvider);
  final user = authAsync.valueOrNull;
  if (user == null) return Stream.value(null);
  return ref
      .read(userProfileRepositoryProvider)
      .watchUserProfile(user.uid);
});

/// Convenience provider that resolves to [true] when the current user has an
/// active premium subscription, and [false] otherwise (including while loading).
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.isPremium ?? false;
});
