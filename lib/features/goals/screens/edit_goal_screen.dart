import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/goal_notifier.dart';
import '../widgets/goal_form.dart';

class EditGoalScreen extends ConsumerStatefulWidget {
  const EditGoalScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  bool _isLoading = false;

  Future<void> _handleSubmit(GoalFormData data) async {
    final goal = ref.read(goalByIdProvider(widget.goalId));
    if (goal == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(goalNotifierProvider.notifier).updateGoal(
            goal.copyWith(
              title: data.title,
              targetAmount: data.targetAmount,
              monthlyContribution: data.monthlyContribution,
              expectedReturnRate: data.expectedReturnRate,
              targetDate: data.targetDate,
            ),
          );
      if (mounted) Navigator.of(context).pop();
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
    final goal = ref.watch(goalByIdProvider(widget.goalId));

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Goal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Goal')),
      body: GoalForm(
        initialGoal: goal,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
        submitLabel: 'Save Changes',
      ),
    );
  }
}
