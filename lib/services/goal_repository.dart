import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../models/sip_entry.dart';
import '../shared/constants.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) => GoalRepository());

class GoalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Goals ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _goalsRef(String userId) => _db
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.goals);

  /// Generates a Firestore auto-ID for a new goal document.
  String generateGoalId(String userId) => _goalsRef(userId).doc().id;

  Stream<List<Goal>> watchGoals(String userId) {
    return _goalsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Goal.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<void> createGoal(String userId, Goal goal) =>
      _goalsRef(userId).doc(goal.id).set(goal.toJson());

  Future<void> updateGoal(String userId, Goal goal) =>
      _goalsRef(userId).doc(goal.id).update(goal.toJson());

  Future<void> deleteGoal(String userId, String goalId) =>
      _goalsRef(userId).doc(goalId).delete();

  // ── SIP Entries ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sipEntriesRef(
    String userId,
    String goalId,
  ) =>
      _goalsRef(userId).doc(goalId).collection(Collections.sipEntries);

  /// Generates a Firestore auto-ID for a new SIP entry document.
  String generateSipEntryId(String userId, String goalId) =>
      _sipEntriesRef(userId, goalId).doc().id;

  Stream<List<SipEntry>> watchSipEntries(String userId, String goalId) {
    return _sipEntriesRef(userId, goalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SipEntry.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Adds a SIP entry and atomically increments the goal's [currentAmount].
  Future<void> addSipEntry(String userId, SipEntry entry) async {
    final batch = _db.batch();
    final sipRef = _sipEntriesRef(userId, entry.goalId).doc(entry.id);
    batch.set(sipRef, entry.toJson());
    final goalRef = _goalsRef(userId).doc(entry.goalId);
    batch.update(goalRef, {
      'currentAmount': FieldValue.increment(entry.amount),
    });
    await batch.commit();
  }

  /// Deletes a SIP entry and atomically decrements the goal's [currentAmount].
  Future<void> deleteSipEntry({
    required String userId,
    required String goalId,
    required String entryId,
    required double amount,
  }) async {
    final batch = _db.batch();
    final sipRef = _sipEntriesRef(userId, goalId).doc(entryId);
    batch.delete(sipRef);
    final goalRef = _goalsRef(userId).doc(goalId);
    batch.update(goalRef, {
      'currentAmount': FieldValue.increment(-amount),
    });
    await batch.commit();
  }
}
