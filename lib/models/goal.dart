import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String userId,
    required String name,
    required double targetAmount,
    required double monthlyContribution,
    required DateTime targetDate,
    @Default(0.0) double currentAmount,
    @Default(12.0) double annualReturnRatePercent,
    DateTime? createdAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
