/// Named route paths used with GoRouter.
abstract final class AppRoutes {
  static const login = '/login';
  static const emailSignIn = '/login/email';
  static const dashboard = '/';
  static const goals = '/goals';
  static const sip = '/sip';
  static const settings = '/settings';

  // Goal sub-routes (used as GoRouter route names).
  static const goalCreate = 'goal-create';
  static const goalDetail = 'goal-detail';
  static const goalEdit = 'goal-edit';
}

/// Firestore collection names.
abstract final class Collections {
  static const users = 'users';
  static const goals = 'goals';
  static const sipEntries = 'sipEntries';
}

/// Free-tier limits for unpaid users.
abstract final class FreeTier {
  static const maxGoals = 3;
}

/// Default SIP projection parameters.
abstract final class SipDefaults {
  static const annualReturnRatePercent = 12.0;
  static const contributionFrequencyMonths = 1;
}

/// Android notification channel configuration.
abstract final class NotificationConfig {
  static const channelId = 'sip_reminders';
  static const channelName = 'SIP Reminders';
  static const channelDesc = 'Monthly reminders before your SIP due date';

  /// Day of month on which the reminder fires — the 28th gives ~2–3 days
  /// of lead time before the 1st-of-month SIP date.
  static const reminderDayOfMonth = 28;
  static const reminderHour = 9;
  static const reminderMinute = 0;
}

/// SharedPreferences key names.
abstract final class PrefsKeys {
  static const notificationsEnabled = 'notifications_enabled';
}
