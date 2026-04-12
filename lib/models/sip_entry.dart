import 'package:cloud_firestore/cloud_firestore.dart';

class SipEntry {
  const SipEntry({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;

  factory SipEntry.fromJson(Map<String, dynamic> json) {
    return SipEntry(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: _toDate(json['date']),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  SipEntry copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return SipEntry(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
