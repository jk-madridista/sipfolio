import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/goal_notifier.dart';
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
