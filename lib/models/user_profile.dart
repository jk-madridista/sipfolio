import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.displayName,
    this.photoUrl,
    this.isPremium = false,
  });

  final String uid;
  final String email;
  final DateTime createdAt;
  final String? displayName;
  final String? photoUrl;
  final bool isPremium;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String,
      createdAt: _toDate(json['createdAt']),
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'createdAt': Timestamp.fromDate(createdAt),
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isPremium': isPremium,
      };

  UserProfile copyWith({
    String? uid,
    String? email,
    DateTime? createdAt,
    String? displayName,
    String? photoUrl,
    bool? isPremium,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
