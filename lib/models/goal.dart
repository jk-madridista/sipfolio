import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.monthlyContribution,
    required this.targetDate,
    required this.createdAt,
    this.currentAmount = 0.0,
    this.expectedReturnRate = 12.0,
    this.isActive = true,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double monthlyContribution;
  final DateTime targetDate;
  final DateTime createdAt;
  final double currentAmount;
  final double expectedReturnRate;
  final bool isActive;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      monthlyContribution: (json['monthlyContribution'] as num).toDouble(),
      targetDate: _toDate(json['targetDate']),
      createdAt: _toDate(json['createdAt']),
      currentAmount: (json['currentAmount'] as num? ?? 0).toDouble(),
      expectedReturnRate:
          (json['expectedReturnRate'] as num? ?? 12.0).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'monthlyContribution': monthlyContribution,
        'targetDate': Timestamp.fromDate(targetDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'currentAmount': currentAmount,
        'expectedReturnRate': expectedReturnRate,
        'isActive': isActive,
      };

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? monthlyContribution,
    DateTime? targetDate,
    DateTime? createdAt,
    double? currentAmount,
    double? expectedReturnRate,
    bool? isActive,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      currentAmount: currentAmount ?? this.currentAmount,
      expectedReturnRate: expectedReturnRate ?? this.expectedReturnRate,
      isActive: isActive ?? this.isActive,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
