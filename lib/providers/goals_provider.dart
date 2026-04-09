import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/goal.dart';
import '../services/goal_repository.dart';
import 'auth_provider.dart';

part 'goals_provider.g.dart';

/// Watches all goals for the currently authenticated user.
@riverpod
Stream<List<Goal>> goals(Ref ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(goalRepositoryProvider).watchGoals(user.uid);
}
