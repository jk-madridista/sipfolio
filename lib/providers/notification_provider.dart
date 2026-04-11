import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../shared/constants.dart';

/// Reads and persists the user's notification-enabled preference.
///
/// [setEnabled] also cancels all scheduled reminders when [false] is passed,
/// and re-schedules them for all active goals when [true] is passed (the
/// caller is expected to supply the goals list for that case — see
/// [SettingsScreen]).
final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferences, bool>(
  NotificationPreferences.new,
);

class NotificationPreferences extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.notificationsEnabled) ?? true;
  }

  /// Persists [enabled] and, when [false], cancels every scheduled reminder.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.notificationsEnabled, enabled);
    if (!enabled) {
      await ref.read(notificationServiceProvider).cancelAll();
    }
    state = AsyncData(enabled);
  }
}
