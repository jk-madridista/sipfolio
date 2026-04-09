import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String title,
    required double targetAmount,
    required double monthlyContribution,
    required DateTime targetDate,
    required DateTime createdAt,
    @Default(0.0) double currentAmount,
    @Default(12.0) double expectedReturnRate,
    @Default(true) bool isActive,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
