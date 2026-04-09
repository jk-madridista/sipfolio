import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/goal.dart';
import '../shared/constants.dart';

part 'goal_repository.g.dart';

@riverpod
GoalRepository goalRepository(Ref ref) => GoalRepository();

class GoalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsRef(String userId) =>
      _db.collection(Collections.users).doc(userId).collection(Collections.goals);

  Stream<List<Goal>> watchGoals(String userId) {
    return _goalsRef(userId).snapshots().map(
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
}
