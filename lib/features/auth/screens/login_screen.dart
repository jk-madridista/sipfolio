import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_notifier.dart';
import '../../../shared/constants.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final isLoading = authAsync.isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        final message = _friendlyError(next.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // ── Hero icon ────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              // ── App name ─────────────────────────────────────────────────
              Text(
                'Sipfolio',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // ── Tagline ──────────────────────────────────────────────────
              Text(
                'Track your SIP investments',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // ── Free-tier badge ──────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Free for up to 3 goals',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // ── Google Sign-In ───────────────────────────────────────────
              FilledButton.icon(
                onPressed:
                    isLoading ? null : () => _signInWithGoogle(ref, context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              // ── Email Sign-In ────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed:
                    isLoading ? null : () => context.pushNamed(AppRoutes.emailSignIn),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Sign in with Email'),
              ),
              const Spacer(),
              // ── Legal footer ─────────────────────────────────────────────
              Text(
                'By signing in you agree to our Terms & Privacy Policy.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(WidgetRef ref, BuildContext context) async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    // Route guard handles navigation on success.
  }

  String _friendlyError(Object? error) {
    final message = error?.toString() ?? '';
    if (message.contains('cancelled') || message.contains('canceled')) {
      return 'Sign-in was cancelled.';
    }
    if (message.contains('network')) {
      return 'Network error. Check your connection.';
    }
    if (message.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email.';
    }
    return 'Sign-in failed. Please try again.';
  }
}
