import '../models/goal.dart';

/// Web stub — all methods are no-ops.
/// flutter_local_notifications and firebase_messaging are not supported on web.
class NotificationService {
  Future<void> initialize() async {}
  Future<bool> requestAndroidPermission() async => true;
  Future<void> scheduleMonthlyReminder(Goal goal) async {}
  Future<void> cancelReminder(String goalId) async {}
  Future<void> cancelAll() async {}
}
