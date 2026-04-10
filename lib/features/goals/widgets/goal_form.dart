import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/goal.dart';
import '../../../shared/constants.dart';

/// Data returned from [GoalForm] when the user submits.
typedef GoalFormData = ({
  String title,
  double targetAmount,
  double monthlyContribution,
  double expectedReturnRate,
  DateTime targetDate,
});

class GoalForm extends ConsumerStatefulWidget {
  const GoalForm({
    super.key,
    this.initialGoal,
    required this.onSubmit,
    this.isLoading = false,
    required this.submitLabel,
  });

  /// Pre-populate fields when editing an existing goal.
  final Goal? initialGoal;
  final void Function(GoalFormData data) onSubmit;
  final bool isLoading;
  final String submitLabel;

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _rateCtrl;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    final g = widget.initialGoal;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _targetCtrl = TextEditingController(
        text: g != null ? g.targetAmount.toStringAsFixed(0) : '');
    _monthlyCtrl = TextEditingController(
        text: g != null ? g.monthlyContribution.toStringAsFixed(0) : '');
    _rateCtrl = TextEditingController(
        text: (g?.expectedReturnRate ?? SipDefaults.annualReturnRatePercent)
            .toStringAsFixed(1));
    _targetDate = g?.targetDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 12);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _monthlyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(DateTime.now().year, DateTime.now().month + 1),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit((
      title: _titleCtrl.text.trim(),
      targetAmount: double.parse(_targetCtrl.text),
      monthlyContribution: double.parse(_monthlyCtrl.text),
      expectedReturnRate: double.parse(_rateCtrl.text),
      targetDate: _targetDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Title ────────────────────────────────────────────────────────
          TextFormField(
            controller: _titleCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              hintText: 'e.g. Emergency Fund',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),

          // ── Target Amount ─────────────────────────────────────────────────
          TextFormField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Target Amount (₹)',
              hintText: 'e.g. 500000',
              prefixIcon: Icon(Icons.savings_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a positive amount';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Monthly SIP ───────────────────────────────────────────────────
          TextFormField(
            controller: _monthlyCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Monthly SIP Amount (₹)',
              hintText: 'e.g. 5000',
              prefixIcon: Icon(Icons.repeat_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a positive SIP amount';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Expected Return Rate ──────────────────────────────────────────
          TextFormField(
            controller: _rateCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Expected Annual Return (%)',
              hintText: '12.0',
              prefixIcon: Icon(Icons.percent_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null) return 'Enter a valid percentage';
              if (n < 0 || n > 50) return 'Rate must be between 0% and 50%';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Target Date ───────────────────────────────────────────────────
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Target Date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              child: Text(formatGoalDate(_targetDate)),
            ),
          ),
          const SizedBox(height: 32),

          // ── Submit ────────────────────────────────────────────────────────
          FilledButton(
            onPressed: widget.isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

/// Formats [d] as "1 Jan 2025".
String formatGoalDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
