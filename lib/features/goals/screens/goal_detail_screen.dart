import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../models/goal.dart';
import '../../../models/sip_entry.dart';
import '../../../providers/auth_notifier.dart';
import '../../../providers/goal_notifier.dart';
import '../../../providers/sip_entries_provider.dart';
import '../../../services/goal_repository.dart';
import '../../../services/sip_projection_engine.dart';
import '../../../shared/constants.dart';
import '../widgets/goal_form.dart' show formatGoalDate;

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalByIdProvider(goalId));

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _GoalDetailView(goal: goal);
  }
}

class _GoalDetailView extends ConsumerWidget {
  const _GoalDetailView({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sipAsync = ref.watch(sipEntriesProvider(goal.id));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final projected = _projectCompletion(goal);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit goal',
            onPressed: () =>
                context.pushNamed(AppRoutes.goalEdit, pathParameters: {'id': goal.id}),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Progress card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 14,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: progress >= 1.0
                                  ? Colors.green
                                  : colorScheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (progress >= 1.0)
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _AmountChip(
                          label: 'Invested',
                          amount: goal.currentAmount,
                          color: colorScheme.primary,
                        ),
                        Container(width: 1, height: 40, color: colorScheme.outline),
                        _AmountChip(
                          label: 'Target',
                          amount: goal.targetAmount,
                          color: colorScheme.secondary,
                        ),
                        Container(width: 1, height: 40, color: colorScheme.outline),
                        _AmountChip(
                          label: 'Remaining',
                          amount: math.max(
                              0, goal.targetAmount - goal.currentAmount),
                          color: colorScheme.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Meta row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: 'Target: ${formatGoalDate(goal.targetDate)}',
                        ),
                        _InfoChip(
                          icon: Icons.trending_up_outlined,
                          label: '${goal.expectedReturnRate.toStringAsFixed(1)}% p.a.',
                        ),
                        _InfoChip(
                          icon: Icons.repeat_outlined,
                          label: '₹${_fmt(goal.monthlyContribution)}/mo',
                        ),
                        if (projected != null)
                          _InfoChip(
                            icon: Icons.flag_outlined,
                            label: 'Est. ${formatGoalDate(projected)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Projection chart ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProjectionChart(goal: goal),
          ),

          // ── SIP entries header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('SIP History', style: textTheme.titleMedium),
            ),
          ),

          // ── SIP entries list ────────────────────────────────────────────
          sipAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No entries yet. Tap + to record a contribution.',
                          style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (ctx, i) => _SipEntryTile(
                  entry: entries[i],
                  goalId: goal.id,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context, ref, goal),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Future<void> _showAddEntrySheet(
      BuildContext context, WidgetRef ref, Goal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddSipEntrySheet(goal: goal),
    );
  }
}

// ── SIP entry tile with swipe-to-delete ─────────────────────────────────────

class _SipEntryTile extends ConsumerWidget {
  const _SipEntryTile({required this.entry, required this.goalId});

  final SipEntry entry;
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _deleteEntry(context, ref),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.currency_rupee,
              size: 18, color: colorScheme.onPrimaryContainer),
        ),
        title: Text('₹${_fmt(entry.amount)}'),
        subtitle: Text(formatGoalDate(entry.date)),
        trailing: entry.note != null
            ? Text(entry.note!,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis)
            : null,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Remove this SIP entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(goalRepositoryProvider).deleteSipEntry(
            userId: user.uid,
            goalId: goalId,
            entryId: entry.id,
            amount: entry.amount,
          );
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ── Add SIP entry bottom sheet ───────────────────────────────────────────────

class _AddSipEntrySheet extends ConsumerStatefulWidget {
  const _AddSipEntrySheet({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_AddSipEntrySheet> createState() => _AddSipEntrySheetState();
}

class _AddSipEntrySheetState extends ConsumerState<_AddSipEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final TextEditingController _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.goal.monthlyContribution.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(goalRepositoryProvider);
      final entryId = repo.generateSipEntryId(user.uid, widget.goal.id);
      final entry = SipEntry(
        id: entryId,
        goalId: widget.goal.id,
        amount: double.parse(_amountCtrl.text),
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      await repo.addSipEntry(user.uid, entry);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Record Contribution',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(formatGoalDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.onPrimary))
                  : const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  const _AmountChip(
      {required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          '₹${_fmt(amount)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Formats a number compactly: 1500000 → "15L", 5000 → "5K".
String _fmt(double n) {
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  return n.toStringAsFixed(0);
}

/// Estimates the month when [goal] will reach its target using the SIP engine.
DateTime? _projectCompletion(Goal goal) {
  final months = SipProjectionEngine.monthsToTarget(
    targetAmount: goal.targetAmount,
    currentAmount: goal.currentAmount,
    monthlyContribution: goal.monthlyContribution,
    annualReturnRate: goal.expectedReturnRate,
  );
  if (months == null || months == 0) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month + months);
}

// ── Projection chart ──────────────────────────────────────────────────────────

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return const SizedBox.shrink();

    final totalMonths = SipProjectionEngine.monthsToTarget(
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      monthlyContribution: goal.monthlyContribution,
      annualReturnRate: goal.expectedReturnRate,
    );
    if (totalMonths == null || totalMonths == 0) return const SizedBox.shrink();

    final projections = SipProjectionEngine.monthByMonth(
      monthlyAmount: goal.monthlyContribution,
      annualReturnRate: goal.expectedReturnRate,
      months: totalMonths,
    );
    if (projections.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // Downsample for performance.
    final step = (projections.length / 120).ceil().clamp(1, 999);
    final sampled = [
      for (var i = 0; i < projections.length; i += step) projections[i],
      projections.last,
    ];

    // Offset by currentAmount so y-axis reflects total portfolio value.
    final investedSpots = sampled
        .map((p) => FlSpot(p.month.toDouble(), goal.currentAmount + p.invested))
        .toList();
    final projectedSpots = sampled
        .map((p) =>
            FlSpot(p.month.toDouble(), goal.currentAmount + p.projectedValue))
        .toList();

    final maxY =
        math.max(goal.targetAmount, projectedSpots.last.y) * 1.05;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  Text('Projection',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  _ChartLegend(
                      color: colorScheme.outlineVariant, label: 'Invested'),
                  const SizedBox(width: 12),
                  _ChartLegend(
                      color: colorScheme.primary, label: 'Projected'),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: totalMonths.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: goal.targetAmount,
                        color: colorScheme.tertiary,
                        strokeWidth: 1,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'Target',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colorScheme.outlineVariant,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (v, _) => Text(
                          '₹${_fmt(v)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval:
                            (totalMonths / 4).clamp(12, 60).toDouble(),
                        getTitlesWidget: (v, _) {
                          final yr = (v / 12).round();
                          return Text(
                            '${yr}yr',
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: investedSpots,
                      isCurved: false,
                      color: colorScheme.outlineVariant,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: projectedSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: colorScheme.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
