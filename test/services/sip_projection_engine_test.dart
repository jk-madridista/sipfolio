import 'package:flutter_test/flutter_test.dart';
import 'package:sipfolio/services/sip_projection_engine.dart';

void main() {
  // ── futureValue ────────────────────────────────────────────────────────────
  group('SipProjectionEngine.futureValue', () {
    test('returns 0 for zero months', () {
      expect(
        SipProjectionEngine.futureValue(
          monthlyAmount: 5000,
          annualReturnRate: 12,
          months: 0,
        ),
        0.0,
      );
    });

    test('returns 0 for negative months', () {
      expect(
        SipProjectionEngine.futureValue(
          monthlyAmount: 5000,
          annualReturnRate: 12,
          months: -6,
        ),
        0.0,
      );
    });

    test('returns 0 for zero monthly amount', () {
      expect(
        SipProjectionEngine.futureValue(
          monthlyAmount: 0,
          annualReturnRate: 12,
          months: 12,
        ),
        0.0,
      );
    });

    test('returns exact sum for 0% annual return rate', () {
      // No compounding: FV = P × n
      expect(
        SipProjectionEngine.futureValue(
          monthlyAmount: 1000,
          annualReturnRate: 0,
          months: 12,
        ),
        closeTo(12000.0, 0.01),
      );
    });

    test('returns near-zero return rate result close to P × n', () {
      // At 0.001% annual rate, result should be barely above P × n.
      final fv = SipProjectionEngine.futureValue(
        monthlyAmount: 1000,
        annualReturnRate: 0.001,
        months: 12,
      );
      expect(fv, closeTo(12000.0, 1.0));
    });

    test('computes FV correctly for 12% annual, 12 months (P=5000)', () {
      // FV = 5000 × ((1.01^12 − 1) / 0.01) × 1.01 ≈ 64,046.64
      final fv = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 12,
      );
      expect(fv, closeTo(64046.64, 0.05));
    });

    test('computes FV correctly for 12% annual, 1 month (P=5000)', () {
      // FV = 5000 × (0.01/0.01) × 1.01 = 5000 × 1.01 = 5050
      final fv = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 1,
      );
      expect(fv, closeTo(5050.0, 0.01));
    });

    test('FV is higher with higher return rate', () {
      final fv12 = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 120,
      );
      final fv15 = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 15,
        months: 120,
      );
      expect(fv15, greaterThan(fv12));
    });

    test('FV is higher with more months', () {
      final fv12 = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 12,
      );
      final fv24 = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 24,
      );
      expect(fv24, greaterThan(fv12));
    });

    test('FV is higher with higher monthly amount', () {
      final fv5k = SipProjectionEngine.futureValue(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 60,
      );
      final fv10k = SipProjectionEngine.futureValue(
        monthlyAmount: 10000,
        annualReturnRate: 12,
        months: 60,
      );
      // Doubling P should exactly double FV (formula is linear in P).
      expect(fv10k, closeTo(fv5k * 2, 0.01));
    });
  });

  // ── monthByMonth ───────────────────────────────────────────────────────────
  group('SipProjectionEngine.monthByMonth', () {
    test('returns empty list for zero months', () {
      expect(
        SipProjectionEngine.monthByMonth(
          monthlyAmount: 5000,
          annualReturnRate: 12,
          months: 0,
        ),
        isEmpty,
      );
    });

    test('returns empty list for negative months', () {
      expect(
        SipProjectionEngine.monthByMonth(
          monthlyAmount: 5000,
          annualReturnRate: 12,
          months: -1,
        ),
        isEmpty,
      );
    });

    test('returns list with correct length', () {
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 24,
      );
      expect(result.length, 24);
    });

    test('month numbers are 1-indexed and sequential', () {
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: 1000,
        annualReturnRate: 12,
        months: 5,
      );
      for (var i = 0; i < result.length; i++) {
        expect(result[i].month, i + 1);
      }
    });

    test('invested equals P × n for each month', () {
      const p = 3000.0;
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: p,
        annualReturnRate: 12,
        months: 6,
      );
      for (var i = 0; i < result.length; i++) {
        expect(result[i].invested, closeTo(p * (i + 1), 0.001));
      }
    });

    test('projected value ≥ invested for non-negative return rate', () {
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 24,
      );
      for (final point in result) {
        expect(point.projectedValue, greaterThanOrEqualTo(point.invested));
      }
    });

    test('projected value is monotonically increasing', () {
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 36,
      );
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].projectedValue,
          greaterThan(result[i - 1].projectedValue),
        );
      }
    });

    test('last month projected value matches futureValue', () {
      const months = 24;
      const monthly = 5000.0;
      const rate = 12.0;
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: monthly,
        annualReturnRate: rate,
        months: months,
      );
      final fv = SipProjectionEngine.futureValue(
        monthlyAmount: monthly,
        annualReturnRate: rate,
        months: months,
      );
      expect(result.last.projectedValue, closeTo(fv, 0.001));
    });

    test('at 0% rate, projected value equals invested each month', () {
      final result = SipProjectionEngine.monthByMonth(
        monthlyAmount: 2000,
        annualReturnRate: 0,
        months: 10,
      );
      for (final point in result) {
        expect(point.projectedValue, closeTo(point.invested, 0.01));
      }
    });
  });

  // ── totalReturns ───────────────────────────────────────────────────────────
  group('SipProjectionEngine.totalReturns', () {
    test('returns zero for 0% rate', () {
      expect(
        SipProjectionEngine.totalReturns(
          monthlyAmount: 5000,
          annualReturnRate: 0,
          months: 12,
        ),
        closeTo(0.0, 0.01),
      );
    });

    test('returns positive value for positive rate', () {
      expect(
        SipProjectionEngine.totalReturns(
          monthlyAmount: 5000,
          annualReturnRate: 12,
          months: 12,
        ),
        greaterThan(0),
      );
    });

    test('equals futureValue minus total invested', () {
      const monthly = 3000.0;
      const months = 36;
      const rate = 10.0;
      final returns = SipProjectionEngine.totalReturns(
        monthlyAmount: monthly,
        annualReturnRate: rate,
        months: months,
      );
      final fv = SipProjectionEngine.futureValue(
        monthlyAmount: monthly,
        annualReturnRate: rate,
        months: months,
      );
      expect(returns, closeTo(fv - monthly * months, 0.001));
    });

    test('grows with higher rate', () {
      final r12 = SipProjectionEngine.totalReturns(
        monthlyAmount: 5000,
        annualReturnRate: 12,
        months: 60,
      );
      final r20 = SipProjectionEngine.totalReturns(
        monthlyAmount: 5000,
        annualReturnRate: 20,
        months: 60,
      );
      expect(r20, greaterThan(r12));
    });
  });

  // ── monthsToTarget ─────────────────────────────────────────────────────────
  group('SipProjectionEngine.monthsToTarget', () {
    test('returns 0 when target already met', () {
      expect(
        SipProjectionEngine.monthsToTarget(
          targetAmount: 100000,
          currentAmount: 100000,
          monthlyContribution: 5000,
          annualReturnRate: 12,
        ),
        0,
      );
    });

    test('returns 0 when current exceeds target', () {
      expect(
        SipProjectionEngine.monthsToTarget(
          targetAmount: 50000,
          currentAmount: 100000,
          monthlyContribution: 5000,
          annualReturnRate: 12,
        ),
        0,
      );
    });

    test('returns null for zero contribution', () {
      expect(
        SipProjectionEngine.monthsToTarget(
          targetAmount: 100000,
          currentAmount: 0,
          monthlyContribution: 0,
          annualReturnRate: 12,
        ),
        isNull,
      );
    });

    test('returns positive integer for valid inputs', () {
      final months = SipProjectionEngine.monthsToTarget(
        targetAmount: 500000,
        currentAmount: 0,
        monthlyContribution: 5000,
        annualReturnRate: 12,
      );
      expect(months, isNotNull);
      expect(months!, greaterThan(0));
    });

    test('fewer months needed with higher contribution', () {
      final m5k = SipProjectionEngine.monthsToTarget(
        targetAmount: 1000000,
        currentAmount: 0,
        monthlyContribution: 5000,
        annualReturnRate: 12,
      )!;
      final m10k = SipProjectionEngine.monthsToTarget(
        targetAmount: 1000000,
        currentAmount: 0,
        monthlyContribution: 10000,
        annualReturnRate: 12,
      )!;
      expect(m10k, lessThan(m5k));
    });

    test('fewer months needed when partial amount already invested', () {
      final mFull = SipProjectionEngine.monthsToTarget(
        targetAmount: 500000,
        currentAmount: 0,
        monthlyContribution: 5000,
        annualReturnRate: 12,
      )!;
      final mPartial = SipProjectionEngine.monthsToTarget(
        targetAmount: 500000,
        currentAmount: 100000,
        monthlyContribution: 5000,
        annualReturnRate: 12,
      )!;
      expect(mPartial, lessThan(mFull));
    });

    test('at 0% rate months ≈ remaining / contribution', () {
      final months = SipProjectionEngine.monthsToTarget(
        targetAmount: 120000,
        currentAmount: 0,
        monthlyContribution: 10000,
        annualReturnRate: 0,
      );
      // 120000 / 10000 = 12 months exactly
      expect(months, 12);
    });
  });
}
