import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/tokens.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        leading: const CloseButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reason != null) ...[
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Radii.cardAll,
                  ),
                  child: Text(reason!, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              Text('Pencraft Pro', style: theme.textTheme.displayMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Everything you need to run a professional business.',
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: Spacing.xl),
              _FeatureRow(icon: Icons.all_inclusive, label: 'Unlimited invoices & estimates'),
              _FeatureRow(icon: Icons.palette_outlined, label: 'All 3 templates + accent colours'),
              _FeatureRow(icon: Icons.image_outlined, label: 'Logo & signature on every PDF'),
              _FeatureRow(icon: Icons.block, label: 'No "Made with Pencraft" footer'),
              _FeatureRow(icon: Icons.ads_click, label: 'Ad-free experience'),
              _FeatureRow(icon: Icons.download_outlined, label: 'CSV export & backup'),
              const SizedBox(height: Spacing.xl),
              // Pricing options
              _PriceOption(
                label: 'Annual',
                price: 'KES 2,499 / year',
                badge: '7-day free trial',
                onTap: () => _purchase(context, 'annual'),
                isPrimary: true,
              ),
              const SizedBox(height: Spacing.sm),
              _PriceOption(
                label: 'Monthly',
                price: 'KES 399 / month',
                onTap: () => _purchase(context, 'monthly'),
              ),
              const SizedBox(height: Spacing.sm),
              _PriceOption(
                label: 'Lifetime',
                price: 'KES 4,999 once',
                onTap: () => _purchase(context, 'lifetime'),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Subscription auto-renews. Cancel anytime in Google Play. Price and terms are always shown clearly before purchase.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () {},
                child: const Text('Restore purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _purchase(BuildContext context, String plan) {
    // TODO(m3): wire to RevenueCatService.purchase()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase flow: $plan (mock mode)')),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _PriceOption extends StatelessWidget {
  const _PriceOption({
    required this.label,
    required this.price,
    required this.onTap,
    this.badge,
    this.isPrimary = false,
  });

  final String label;
  final String price;
  final VoidCallback onTap;
  final String? badge;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onTap,
        child: Column(
          children: [
            if (badge != null)
              Text(badge!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onPrimary)),
            Text('$label · $price'),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: onTap,
      child: Text('$label · $price'),
    );
  }
}
