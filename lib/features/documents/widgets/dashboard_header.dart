import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/tokens.dart';
import '../../../core/currency_formatter.dart';
import '../providers/document_providers.dart';

/// Animated dashboard header showing key totals.
/// Count-up animation fires once per session on first load.
class DashboardHeader extends ConsumerStatefulWidget {
  const DashboardHeader({super.key, required this.documents});

  final List<dynamic> documents;

  @override
  ConsumerState<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends ConsumerState<DashboardHeader> {
  bool _animated = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalsAsync = ref.watch(dashboardTotalsProvider);

    return totalsAsync.when(
      data: (totals) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_animated && mounted) setState(() => _animated = true);
        });
        return _buildHeader(context, theme, totals);
      },
      loading: () => _buildHeader(context, theme, const DashboardTotals.zero()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, DashboardTotals totals) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _TotalTile(
                label: 'Outstanding',
                amountMinor: totals.outstandingMinor,
                currency: totals.currency,
                color: theme.colorScheme.onSurface,
                animate: _animated,
              ),
            ),
            _Divider(),
            Expanded(
              child: _TotalTile(
                label: 'Overdue',
                amountMinor: totals.overdueMinor,
                currency: totals.currency,
                color: theme.colorScheme.error,
                animate: _animated,
              ),
            ),
            _Divider(),
            Expanded(
              child: _TotalTile(
                label: 'Paid this month',
                amountMinor: totals.paidThisMonthMinor,
                currency: totals.currency,
                color: const Color(0xFF1E7D45),
                animate: _animated,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.label,
    required this.amountMinor,
    required this.currency,
    required this.color,
    required this.animate,
  });

  final String label;
  final int amountMinor;
  final String currency;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          animate
              ? TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: amountMinor),
                  duration: Motion.countUp,
                  curve: Motion.decelerate,
                  builder: (_, value, __) => _AmountText(
                    value: value,
                    currency: currency,
                    color: color,
                    theme: theme,
                  ),
                )
              : _AmountText(
                  value: 0,
                  currency: currency,
                  color: color,
                  theme: theme,
                ),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({
    required this.value,
    required this.currency,
    required this.color,
    required this.theme,
  });

  final int value;
  final String currency;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyFormatter.format(value, currency),
      style: theme.textTheme.titleMedium?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
