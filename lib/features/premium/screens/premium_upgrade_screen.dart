import 'package:flutter/material.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  static const _benefits = [
    _Benefit(
      icon: Icons.all_inclusive,
      title: 'Unlimited Goals',
      description: 'Create as many SIP goals as you need — no caps, no limits.',
    ),
    _Benefit(
      icon: Icons.block,
      title: 'Ad-Free Experience',
      description: 'Enjoy Sipfolio without any banner or interstitial ads.',
    ),
    _Benefit(
      icon: Icons.download_outlined,
      title: 'CSV Export',
      description:
          'Export your goals and SIP history as a spreadsheet for your records.',
    ),
    _Benefit(
      icon: Icons.support_agent_outlined,
      title: 'Priority Support',
      description: 'Get faster responses from our support team.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.workspace_premium,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sipfolio Premium',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock the full experience',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Benefits list ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverList.separated(
              itemCount: _benefits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _BenefitCard(benefit: _benefits[i]),
            ),
          ),

          // ── Pricing card ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'One-time purchase',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹299',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lifetime access — no subscription',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── CTA buttons ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: FilledButton(
                onPressed: () => _onUpgradeTap(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: TextButton(
                onPressed: () => _onRestoreTap(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Restore Purchase'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onUpgradeTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Play Billing coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRestoreTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restore purchase coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Benefit data class ────────────────────────────────────────────────────────

class _Benefit {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

// ── Benefit card widget ───────────────────────────────────────────────────────

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(benefit.icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    benefit.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
