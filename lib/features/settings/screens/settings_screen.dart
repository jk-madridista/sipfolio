import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/goal.dart';
import '../../../providers/auth_notifier.dart';
import '../../../providers/goal_notifier.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final notificationsEnabled = prefsAsync.valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ── Notifications ─────────────────────────────────────────────────
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('SIP Reminders'),
            subtitle: const Text(
              'Monthly reminder on the 28th — 2–3 days before your '
              'next SIP date',
            ),
            value: notificationsEnabled,
            onChanged: prefsAsync.isLoading
                ? null
                : (enabled) => _onNotificationToggle(ref, enabled),
          ),
          const Divider(),

          // ── Premium ───────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Upgrade to Premium'),
            subtitle: const Text('Unlimited goals, no ads, CSV export'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: open premium upgrade flow
            },
          ),
          const Divider(),

          // ── Sign out ──────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationToggle(WidgetRef ref, bool enabled) async {
    await ref
        .read(notificationPreferencesProvider.notifier)
        .setEnabled(enabled);

    // When re-enabling, schedule reminders for every currently active goal
    // so the user doesn't have to edit each goal individually.
    if (enabled) {
      final goals = ref.read(goalNotifierProvider).valueOrNull ?? <Goal>[];
      final service = ref.read(notificationServiceProvider);
      for (final goal in goals) {
        if (goal.isActive) {
          await service.scheduleMonthlyReminder(goal);
        }
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      // Route guard redirects to login after sign-out.
    }
  }
}
