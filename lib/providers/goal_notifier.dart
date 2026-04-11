import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/goal.dart';
import '../providers/auth_notifier.dart';
import '../providers/notification_provider.dart';
import '../services/goal_repository.dart';
import '../services/notification_service.dart';

part 'goal_notifier.g.dart';

/// Streams the authenticated user's goals and exposes CRUD operations.
///
/// Uses a Firestore real-time listener so mutations from other devices are
/// reflected automatically without manual state updates.
@riverpod
class GoalNotifier extends _$GoalNotifier {
  @override
  Stream<List<Goal>> build() {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    if (user == null) return Stream.value([]);
    return ref.watch(goalRepositoryProvider).watchGoals(user.uid);
  }

  /// Creates a new goal and, when notifications are enabled, schedules a
  /// monthly SIP reminder for it.
  Future<void> createGoal({
    required String title,
    required double targetAmount,
    required double monthlyContribution,
    required double expectedReturnRate,
    required DateTime targetDate,
  }) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');

    final repo = ref.read(goalRepositoryProvider);
    final id = repo.generateGoalId(user.uid);
    final goal = Goal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      monthlyContribution: monthlyContribution,
      expectedReturnRate: expectedReturnRate,
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );
    await repo.createGoal(user.uid, goal);

    if (_notificationsEnabled) {
      await ref.read(notificationServiceProvider).scheduleMonthlyReminder(goal);
    }
  }

  /// Updates an existing goal. Reschedules the monthly reminder (or cancels
  /// it if notifications have been disabled).
  Future<void> updateGoal(Goal goal) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');
    await ref.read(goalRepositoryProvider).updateGoal(user.uid, goal);

    final service = ref.read(notificationServiceProvider);
    if (_notificationsEnabled) {
      await service.scheduleMonthlyReminder(goal);
    } else {
      await service.cancelReminder(goal.id);
    }
  }

  /// Deletes a goal and cancels its scheduled reminder.
  Future<void> deleteGoal(String goalId) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) throw StateError('Not authenticated');
    await ref.read(goalRepositoryProvider).deleteGoal(user.uid, goalId);
    await ref.read(notificationServiceProvider).cancelReminder(goalId);
  }

  bool get _notificationsEnabled =>
      ref.read(notificationPreferencesProvider).valueOrNull ?? true;
}

/// Returns a single [Goal] by [goalId] from the current goals stream,
/// or null if not found.
@riverpod
Goal? goalById(Ref ref, String goalId) {
  final goals = ref.watch(goalNotifierProvider).valueOrNull ?? [];
  for (final g in goals) {
    if (g.id == goalId) return g;
  }
  return null;
}
