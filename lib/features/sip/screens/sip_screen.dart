import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../services/sip_projection_engine.dart';

class SipScreen extends StatefulWidget {
  const SipScreen({super.key});

  @override
  State<SipScreen> createState() => _SipScreenState();
}

class _SipScreenState extends State<SipScreen> {
  double _monthlyAmount = 5000;
  int _durationYears = 10;
  double _annualRate = 12.0;

  @override
  Widget build(BuildContext context) {
    final months = _durationYears * 12;
    final fv = SipProjectionEngine.futureValue(
      monthlyAmount: _monthlyAmount,
      annualReturnRate: _annualRate,
      months: months,
    );
    final totalInvested = _monthlyAmount * months;
    final returns = SipProjectionEngine.totalReturns(
      monthlyAmount: _monthlyAmount,
      annualReturnRate: _annualRate,
      months: months,
    );
    final projections = SipProjectionEngine.monthByMonth(
      monthlyAmount: _monthlyAmount,
      annualReturnRate: _annualRate,
      months: months,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('SIP Calculator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Input sliders ─────────────────────────────────────────────────
          _SliderTile(
            label: 'Monthly SIP',
            displayValue: '₹${_fmtCompact(_monthlyAmount)}',
            value: _monthlyAmount,
            min: 500,
            max: 100000,
            divisions: 199, // steps of 500
            onChanged: (v) =>
                setState(() => _monthlyAmount = (v / 500).round() * 500),
          ),
          _SliderTile(
            label: 'Duration',
            displayValue: '$_durationYears yr',
            value: _durationYears.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => setState(() => _durationYears = v.round()),
          ),
          _SliderTile(
            label: 'Expected Return',
            displayValue: '${_annualRate.toStringAsFixed(1)}% p.a.',
            value: _annualRate,
            min: 1,
            max: 30,
            divisions: 58, // steps of 0.5%
            onChanged: (v) =>
                setState(() => _annualRate = (v * 2).round() / 2),
          ),

          const SizedBox(height: 8),

          // ── Results card ──────────────────────────────────────────────────
          _ResultsCard(
            totalInvested: totalInvested,
            returns: returns,
            totalValue: fv,
          ),

          const SizedBox(height: 16),

          // ── Growth chart ──────────────────────────────────────────────────
          _GrowthChart(projections: projections),
        ],
      ),
    );
  }
}

// ── Slider tile ───────────────────────────────────────────────────────────────

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.displayValue,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String displayValue;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      )),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Results card ──────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.totalInvested,
    required this.returns,
    required this.totalValue,
  });

  final double totalInvested;
  final double returns;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Wealth ratio bar: what fraction is returns vs invested?
    final returnsRatio =
        totalValue > 0 ? (returns / totalValue).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big total
            Center(
              child: Column(
                children: [
                  Text('Total Value',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_fmtLong(totalValue)}',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Invested vs returns bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - returnsRatio,
                minHeight: 10,
                backgroundColor: colorScheme.secondary.withOpacity(0.8),
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: colorScheme.surfaceContainerHighest,
                    label: 'Invested  ₹${_fmtLong(totalInvested)}'),
                const Spacer(),
                _LegendDot(color: colorScheme.secondary,
                    label: 'Returns  ₹${_fmtLong(returns)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Growth chart ──────────────────────────────────────────────────────────────

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.projections});

  final List<SipProjection> projections;

  @override
  Widget build(BuildContext context) {
    if (projections.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final maxValue = projections.last.projectedValue;

    // Downsample to at most 120 points for smooth rendering.
    final step = (projections.length / 120).ceil().clamp(1, 999);
    final sampled = [
      for (var i = 0; i < projections.length; i += step) projections[i],
      projections.last, // always include the final point
    ];

    final investedSpots = sampled
        .map((p) => FlSpot(p.month.toDouble(), p.invested))
        .toList();
    final projectedSpots = sampled
        .map((p) => FlSpot(p.month.toDouble(), p.projectedValue))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  _ChartLegend(
                      color: colorScheme.surfaceContainerHighest,
                      label: 'Invested'),
                  const SizedBox(width: 16),
                  _ChartLegend(
                      color: colorScheme.primary, label: 'Projected'),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: projections.last.month.toDouble(),
                  minY: 0,
                  maxY: maxValue * 1.05,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
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
                          '₹${_fmtCompact(v)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (projections.length / 5)
                            .clamp(12, 72)
                            .toDouble(),
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
                    // Invested line (straight, muted)
                    LineChartBarData(
                      spots: investedSpots,
                      isCurved: false,
                      color: colorScheme.outlineVariant,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      belowBarData:
                          BarAreaData(show: false),
                    ),
                    // Projected growth line
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
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

/// Compact: 1500000 → "15L", 75000 → "75K".
String _fmtCompact(double n) {
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

/// Long form with commas, e.g. 150000 → "1,50,000".
String _fmtLong(double n) {
  final s = n.toStringAsFixed(0);
  if (s.length <= 3) return s;
  // Indian number formatting: last 3 digits, then groups of 2.
  final buf = StringBuffer();
  final rev = s.split('').reversed.toList();
  for (var i = 0; i < rev.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(rev[i]);
  }
  return buf.toString().split('').reversed.join();
}
