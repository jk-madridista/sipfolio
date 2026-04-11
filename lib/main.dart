import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/notification_service.dart';

/// Top-level FCM background message handler.
///
/// Must be a top-level function and annotated with `@pragma('vm:entry-point')`
/// so the AOT compiler does not tree-shake it.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Must be registered before runApp.
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Pre-initialise the notification service (timezone DB + channels) so the
  // first scheduleMonthlyReminder call has no extra setup latency. The same
  // instance is injected via ProviderScope so the whole app shares it.
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const SipfolioApp(),
    ),
  );
}
