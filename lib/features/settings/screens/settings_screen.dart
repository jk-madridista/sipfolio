import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              // TODO: sign out via auth provider
            },
          ),
        ],
      ),
    );
  }
}
