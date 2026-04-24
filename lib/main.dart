import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/notification_service.dart';
import 'utils/ads_initializer.dart';
import 'utils/fcm_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Conditional imports in the helpers make these safe on every platform.
  await initializeAds();
  await initializeFcm();

  // Pre-initialise the notification service (timezone DB + channels) so the
  // first scheduleMonthlyReminder call has no extra setup latency. The same
  // instance is injected via ProviderScope so the whole app shares it.
  // Skipped on web — the stub's initialize() is a no-op.
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
