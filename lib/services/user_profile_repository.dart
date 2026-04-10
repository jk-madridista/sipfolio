import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_profile.dart';
import '../shared/constants.dart';

part 'user_profile_repository.g.dart';

@riverpod
UserProfileRepository userProfileRepository(Ref ref) =>
    UserProfileRepository();

class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a [UserProfile] document in Firestore for [user] if one does not
  /// already exist. Safe to call on every login.
  Future<void> ensureUserProfile(User user) async {
    final docRef =
        _firestore.collection(Collections.users).doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: DateTime.now(),
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
      await docRef.set(profile.toJson());
    }
  }

  /// Returns the [UserProfile] for the given [uid], or null if not found.
  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot =
        await _firestore.collection(Collections.users).doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserProfile.fromJson(snapshot.data()!);
  }
}
