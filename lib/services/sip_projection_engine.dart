import 'dart:math' as math;

/// A single data point in a month-by-month SIP projection.
class SipProjection {
  const SipProjection({
    required this.month,
    required this.invested,
    required this.projectedValue,
  });

  /// 1-indexed month number.
  final int month;

  /// Total amount invested up to this month: [monthlyAmount] × [month].
  final double invested;

  /// Projected corpus value at this month using the SIP compound-interest
  /// formula.
  final double projectedValue;
}

/// Pure-Dart SIP (Systematic Investment Plan) calculation engine.
///
/// All methods are static and have no side-effects; safe to call from any
/// isolate or test.
abstract final class SipProjectionEngine {
  // ── Core formula ────────────────────────────────────────────────────────────

  /// Computes the future value of a SIP after [months] using:
  ///
  /// ```
  /// FV = P × [((1 + r)ⁿ − 1) / r] × (1 + r)
  /// ```
  ///
  /// where:
  /// - P  = [monthlyAmount]
  /// - r  = [annualReturnRate] / 100 / 12  (monthly rate)
  /// - n  = [months]
  ///
  /// The `× (1 + r)` term treats contributions as beginning-of-period
  /// (annuity-due), which is the standard SIP convention.
  ///
  /// Returns 0 when [months] ≤ 0 or [monthlyAmount] ≤ 0.
  static double futureValue({
    required double monthlyAmount,
    required double annualReturnRate,
    required int months,
  }) {
    if (months <= 0 || monthlyAmount <= 0) return 0;

    final r = annualReturnRate / 100 / 12;

    if (r < 1e-9) {
      // Zero (or near-zero) rate: FV = P × n.
      return monthlyAmount * months;
    }

    return monthlyAmount *
        ((math.pow(1 + r, months) - 1) / r) *
        (1 + r);
  }

  // ── Projection table ────────────────────────────────────────────────────────

  /// Returns a month-by-month projection from month 1 to [months].
  ///
  /// Each [SipProjection] contains:
  /// - [SipProjection.month]: 1-indexed month number
  /// - [SipProjection.invested]: cumulative amount put in
  /// - [SipProjection.projectedValue]: expected corpus at that month
  ///
  /// Returns an empty list when [months] ≤ 0.
  static List<SipProjection> monthByMonth({
    required double monthlyAmount,
    required double annualReturnRate,
    required int months,
  }) {
    if (months <= 0) return const [];

    return List.generate(months, (i) {
      final n = i + 1;
      return SipProjection(
        month: n,
        invested: monthlyAmount * n,
        projectedValue: futureValue(
          monthlyAmount: monthlyAmount,
          annualReturnRate: annualReturnRate,
          months: n,
        ),
      );
    });
  }

  // ── Derived helpers ─────────────────────────────────────────────────────────

  /// Total returns (interest earned) = [futureValue] − total invested.
  static double totalReturns({
    required double monthlyAmount,
    required double annualReturnRate,
    required int months,
  }) {
    final fv = futureValue(
      monthlyAmount: monthlyAmount,
      annualReturnRate: annualReturnRate,
      months: months,
    );
    return fv - monthlyAmount * months;
  }

  /// Estimates the number of months needed for a SIP to grow the
  /// **remaining** amount ([targetAmount] − [currentAmount]) to zero.
  ///
  /// Uses the inverse of the FV formula:
  /// ```
  /// n = log(1 + remaining × r / P) / log(1 + r)
  /// ```
  ///
  /// Returns `0` when the target is already met, `null` when the
  /// projection cannot converge (e.g. zero contribution or rate makes
  /// the formula undefined).
  static int? monthsToTarget({
    required double targetAmount,
    required double currentAmount,
    required double monthlyContribution,
    required double annualReturnRate,
  }) {
    final remaining = targetAmount - currentAmount;
    if (remaining <= 0) return 0;
    if (monthlyContribution <= 0) return null;

    final r = annualReturnRate / 100 / 12;
    final double n;

    if (r < 1e-9) {
      n = remaining / monthlyContribution;
    } else {
      final val = 1 + remaining * r / monthlyContribution;
      if (val <= 0) return null;
      n = math.log(val) / math.log(1 + r);
    }

    if (n.isNaN || n.isInfinite || n < 0) return null;
    return n.ceil();
  }
}
