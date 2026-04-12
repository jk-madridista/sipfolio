import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/goal.dart';
import '../../../providers/goal_notifier.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../shared/constants.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return _EmptyState(
              onCreateTap: () => _navigateToCreate(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: goals.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) => _GoalTile(goal: goals[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context, ref),
        tooltip: 'New Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Navigates to [CreateGoalScreen], or shows an upgrade prompt if the
  /// free-tier goal limit has been reached.
  void _navigateToCreate(BuildContext context, WidgetRef ref) {
    final isPremium = ref.read(isPremiumProvider);
    final goals = ref.read(goalNotifierProvider).valueOrNull ?? [];
    if (!isPremium && goals.length >= FreeTier.maxGoals) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.workspace_premium, size: 32),
          title: const Text('Goal limit reached'),
          content: Text(
            'Free accounts support up to ${FreeTier.maxGoals} goals. '
            'Upgrade to Premium for unlimited goals and more.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pushNamed(AppRoutes.premiumUpgrade);
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
    context.pushNamed(AppRoutes.goalCreate);
  }
}

// ── Goal list tile with swipe-to-delete ──────────────────────────────────────

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context, goal.title),
      onDismissed: (_) =>
          ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id),
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.goalDetail,
          pathParameters: {'id': goal.id},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: progress >= 1.0 ? Colors.green : colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${_fmt(goal.currentAmount)} of ₹${_fmt(goal.targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '₹${_fmt(goal.monthlyContribution)}/mo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 72, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No goals yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first SIP goal to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(double n) {
  if (n >= 100000) {
    return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  }
  return n.toStringAsFixed(0);
}
