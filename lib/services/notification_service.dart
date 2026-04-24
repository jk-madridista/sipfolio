import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_stub.dart';

export 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_stub.dart'
    show NotificationService;

/// Provides a single shared [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
