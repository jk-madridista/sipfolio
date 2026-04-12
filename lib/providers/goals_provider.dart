import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../services/goal_repository.dart';
import 'auth_provider.dart';

/// Watches all goals for the currently authenticated user.
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(goalRepositoryProvider).watchGoals(user.uid);
});
