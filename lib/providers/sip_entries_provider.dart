import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sip_entry.dart';
import '../providers/auth_notifier.dart';
import '../services/goal_repository.dart';

/// Streams all [SipEntry] records for the given [goalId], scoped to the
/// currently authenticated user.
final sipEntriesProvider =
    StreamProvider.family<List<SipEntry>, String>((ref, goalId) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(goalRepositoryProvider).watchSipEntries(user.uid, goalId);
});
