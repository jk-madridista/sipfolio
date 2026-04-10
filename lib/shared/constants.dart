/// Named route paths used with GoRouter.
abstract final class AppRoutes {
  static const login = '/login';
  static const emailSignIn = '/login/email';
  static const dashboard = '/';
  static const goals = '/goals';
  static const sip = '/sip';
  static const settings = '/settings';
}

/// Firestore collection names.
abstract final class Collections {
  static const users = 'users';
  static const goals = 'goals';
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
