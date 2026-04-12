import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/goal.dart';
import '../shared/constants.dart';

/// Provides a single shared [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Manages local SIP-reminder notifications and Firebase Cloud Messaging
/// permission.
///
/// Call [initialize] once at app startup. All other methods call
/// [_ensureInitialized] internally so they are safe to call at any time.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Initialises the timezone database, the local-notifications plugin, and
  /// requests FCM + OS-level notification permission.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Timezone
    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.name));

    // 2. flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    // 3. FCM permission (also triggers the OS dialog on iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  /// Requests the Android OS notification permission (Android 13 / API 33+).
  ///
  /// Returns `true` if permission was granted or already held.
  Future<bool> requestAndroidPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? true;
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Schedules a recurring monthly notification for [goal].
  ///
  /// The notification fires on the [NotificationConfig.reminderDayOfMonth]th
  /// of each month at [NotificationConfig.reminderHour]:00 local time, giving
  /// the user ~2 days' notice before their 1st-of-month SIP date.
  ///
  /// Any existing notification for the same goal is replaced.
  Future<void> scheduleMonthlyReminder(Goal goal) async {
    await _ensureInitialized();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationConfig.channelId,
        NotificationConfig.channelName,
        channelDescription: NotificationConfig.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.zonedSchedule(
      _idFor(goal.id),
      'SIP Reminder: ${goal.title}',
      'Your ₹${_fmtAmount(goal.monthlyContribution)} SIP is due in a '
          'couple of days. Stay on track!',
      _nextOccurrence(),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Cancels the scheduled reminder for [goalId], if any.
  Future<void> cancelReminder(String goalId) async {
    await _ensureInitialized();
    await _plugin.cancel(_idFor(goalId));
  }

  /// Cancels every scheduled reminder.
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  /// Converts a goal ID string to a stable int notification ID.
  int _idFor(String goalId) => goalId.hashCode.abs() % 100000;

  /// Returns the next occurrence of [NotificationConfig.reminderDayOfMonth]
  /// at [NotificationConfig.reminderHour]:00 local time.
  ///
  /// If that moment has already passed this month, returns the same
  /// day-of-month in the following month.
  tz.TZDateTime _nextOccurrence() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      NotificationConfig.reminderDayOfMonth,
      NotificationConfig.reminderHour,
      NotificationConfig.reminderMinute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        NotificationConfig.reminderDayOfMonth,
        NotificationConfig.reminderHour,
        NotificationConfig.reminderMinute,
      );
    }
    return scheduled;
  }

  /// Compact Indian-style amount: 150000 → "1.5L", 5000 → "5K".
  String _fmtAmount(double n) {
    if (n >= 100000) {
      return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toStringAsFixed(0);
  }
}
