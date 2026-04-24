import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
/// All methods are no-ops on web — [kIsWeb] guards prevent any mobile-only
/// API from being called at runtime.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<bool> requestAndroidPermission() async {
    if (kIsWeb) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? true;
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  Future<void> scheduleMonthlyReminder(Goal goal) async {
    if (kIsWeb) return;
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

  Future<void> cancelReminder(String goalId) async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancel(_idFor(goalId));
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (kIsWeb || _initialized) return;
    await initialize();
  }

  int _idFor(String goalId) => goalId.hashCode.abs() % 100000;

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
