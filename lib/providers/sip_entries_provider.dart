import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/sip_entry.dart';
import '../providers/auth_notifier.dart';
import '../services/goal_repository.dart';

part 'sip_entries_provider.g.dart';

/// Streams all [SipEntry] records for the given [goalId], scoped to the
/// currently authenticated user.
@riverpod
Stream<List<SipEntry>> sipEntries(Ref ref, String goalId) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(goalRepositoryProvider).watchSipEntries(user.uid, goalId);
}
