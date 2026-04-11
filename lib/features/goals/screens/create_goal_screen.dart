import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/goal_notifier.dart';
import '../../../shared/constants.dart';
import '../widgets/goal_form.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  bool _isLoading = false;

  Future<void> _handleSubmit(GoalFormData data) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(goalNotifierProvider.notifier).createGoal(
            title: data.title,
            targetAmount: data.targetAmount,
            monthlyContribution: data.monthlyContribution,
            expectedReturnRate: data.expectedReturnRate,
            targetDate: data.targetDate,
          );
      if (mounted) Navigator.of(context).pop();
    } on GoalLimitReachedException {
      if (!mounted) return;
      // Redirect the user to the premium upgrade screen instead of showing
      // a generic error — they hit the free-tier cap.
      await showDialog<void>(
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
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Goal')),
      body: GoalForm(
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
        submitLabel: 'Create Goal',
      ),
    );
  }
}
