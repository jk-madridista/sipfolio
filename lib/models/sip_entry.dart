import 'package:freezed_annotation/freezed_annotation.dart';

part 'sip_entry.freezed.dart';
part 'sip_entry.g.dart';

@freezed
class SipEntry with _$SipEntry {
  const factory SipEntry({
    required String id,
    required String goalId,
    required double amount,
    required DateTime date,
    String? note,
  }) = _SipEntry;

  factory SipEntry.fromJson(Map<String, dynamic> json) =>
      _$SipEntryFromJson(json);
}
