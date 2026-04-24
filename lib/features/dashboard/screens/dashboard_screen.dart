import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../models/goal.dart';
import '../../../providers/auth_notifier.dart';
import '../../../providers/goal_notifier.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/sip_projection_engine.dart';
import '../../../shared/constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final goalsAsync = ref.watch(goalNotifierProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final activeGoals = goals.where((g) => g.isActive).toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: _GreetingHeader(user: user),
                ),
              ),
              if (activeGoals.isNotEmpty)
                SliverToBoxAdapter(
                  child: _SummaryCard(goals: activeGoals),
                ),
              if (activeGoals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    onCreateTap: () => _navigateToCreate(context, ref),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList.separated(
                    itemCount: activeGoals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _GoalCard(goal: activeGoals[i]),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad — shown only for free users.
          if (!isPremium) const _BannerAdWidget(),
          NavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.goNamed(AppRoutes.dashboard);
                case 1:
                  context.goNamed(AppRoutes.goals);
                case 2:
                  context.goNamed(AppRoutes.sip);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag),
                label: 'Goals',
              ),
              NavigationDestination(
                icon: Icon(Icons.calculate_outlined),
                selectedIcon: Icon(Icons.calculate),
                label: 'SIP Calc',
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context, ref),
        tooltip: 'Create goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Navigates to [CreateGoalScreen], or to [PremiumUpgradeScreen] if the
  /// free-tier goal limit has been reached.
  void _navigateToCreate(BuildContext context, WidgetRef ref) {
    final isPremium = ref.read(isPremiumProvider);
    final goals = ref.read(goalNotifierProvider).valueOrNull ?? [];
    if (!isPremium && goals.length >= FreeTier.maxGoals) {
      _showUpgradeDialog(context);
      return;
    }
    context.pushNamed(AppRoutes.goalCreate);
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 32),
        title: const Text('Goal limit reached'),
        content: Text(
          'Free accounts support up to ${FreeTier.maxGoals} goals. '
          'Upgrade to Premium for unlimited goals and more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushNamed(AppRoutes.premiumUpgrade);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ── Banner ad ─────────────────────────────────────────────────────────────────

/// Loads and displays an AdMob banner. Uses the public test ad-unit ID so no
/// real inventory is needed during development. Swap to a production unit ID
/// before release.
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  static const _adUnitId = AdConfig.testBannerAdUnitId;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;
    final ad = BannerAd(
      adUnitId: _BannerAdWidget._adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ── Greeting header ───────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final firstName = _firstName(user?.displayName);
    final photoUrl = user?.photoURL;
    final initial = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName![0].toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your investment overview',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.pushNamed(AppRoutes.settings),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _firstName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return 'there';
    return displayName.trim().split(' ').first;
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalInvested =
        goals.fold<double>(0, (s, g) => s + g.currentAmount);
    final totalProjected =
        goals.fold<double>(0, (s, g) => s + _computeProjectedValue(g));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Invested',
                  value: '₹${_fmt(totalInvested)}',
                  icon: Icons.savings_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              VerticalDivider(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                width: 1,
                indent: 4,
                endIndent: 4,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Projected',
                  value: '₹${_fmt(totalProjected)}',
                  icon: Icons.trending_up_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              VerticalDivider(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                width: 1,
                indent: 4,
                endIndent: 4,
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Active Goals',
                  value: '${goals.length}',
                  icon: Icons.flag_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final completion = _projectedCompletion(goal);

    return Hero(
      tag: 'goal-card-${goal.id}',
      transitionOnUserGestures: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(
            AppRoutes.goalDetail,
            pathParameters: {'id': goal.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: textTheme.labelMedium?.copyWith(
                        color: progress >= 1.0
                            ? Colors.green
                            : colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Animated progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 6),

              // Amount labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${_fmt(goal.currentAmount)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${_fmt(goal.targetAmount)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // SIP amount + projected completion
              Row(
                children: [
                  Icon(
                    Icons.repeat_outlined,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₹${_fmt(goal.monthlyContribution)}/mo',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (completion != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatMonthYear(completion),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),   // Card
    );   // Hero
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 88,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No goals yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your SIP journey by creating\nyour first investment goal.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: const Text('Create your first goal'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Compact Indian-style number format: 1500000 → "15L", 5000 → "5K".
String _fmt(double n) {
  if (n >= 100000) {
    return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 1)}L';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
  }
  return n.toStringAsFixed(0);
}

/// Projected corpus at [goal]'s target date = current amount + SIP FV for
/// the remaining months.
double _computeProjectedValue(Goal goal) {
  final now = DateTime.now();
  final months = ((goal.targetDate.year - now.year) * 12 +
          (goal.targetDate.month - now.month))
      .clamp(0, 9999);
  return goal.currentAmount +
      SipProjectionEngine.futureValue(
        monthlyAmount: goal.monthlyContribution,
        annualReturnRate: goal.expectedReturnRate,
        months: months,
      );
}

/// Estimated date when [goal] will reach its target via SIP contributions.
DateTime? _projectedCompletion(Goal goal) {
  final months = SipProjectionEngine.monthsToTarget(
    targetAmount: goal.targetAmount,
    currentAmount: goal.currentAmount,
    monthlyContribution: goal.monthlyContribution,
    annualReturnRate: goal.expectedReturnRate,
  );
  if (months == null || months == 0) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month + months);
}

/// Formats a [DateTime] as "Mon YYYY" (e.g. "Jan 2027").
String _formatMonthYear(DateTime date) {
  const abbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${abbr[date.month - 1]} ${date.year}';
}
