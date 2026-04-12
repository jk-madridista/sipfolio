import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/email_signin_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/goals/screens/create_goal_screen.dart';
import '../features/goals/screens/edit_goal_screen.dart';
import '../features/goals/screens/goal_detail_screen.dart';
import '../features/goals/screens/goals_screen.dart';
import '../features/premium/screens/premium_upgrade_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/sip/screens/sip_screen.dart';
import '../providers/auth_notifier.dart';
import '../shared/constants.dart';

/// A [ChangeNotifier] that triggers GoRouter to re-evaluate its redirect logic
/// whenever the authentication state changes.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);

      // While loading auth state, stay on current screen.
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.emailSignIn;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailSignIn,
        name: AppRoutes.emailSignIn,
        builder: (context, state) => const EmailSignInScreen(),
      ),

      // ── App shell ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.sip,
        name: AppRoutes.sip,
        builder: (context, state) => const SipScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.premiumUpgrade,
        name: AppRoutes.premiumUpgrade,
        builder: (context, state) => const PremiumUpgradeScreen(),
      ),

      // ── Goals (nested) ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.goals,
        name: AppRoutes.goals,
        builder: (context, state) => const GoalsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: AppRoutes.goalCreate,
            builder: (context, state) => const CreateGoalScreen(),
          ),
          GoRoute(
            path: ':id',
            name: AppRoutes.goalDetail,
            builder: (context, state) => GoalDetailScreen(
              goalId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: AppRoutes.goalEdit,
                builder: (context, state) => EditGoalScreen(
                  goalId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
