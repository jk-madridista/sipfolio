import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../shared/constants.dart';
import '../shared/theme.dart';
import 'routes.dart';

class SipfolioApp extends ConsumerWidget {
  const SipfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider).valueOrNull
        ?? ThemeMode.system;

    return MaterialApp.router(
      title: AppMeta.name,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
