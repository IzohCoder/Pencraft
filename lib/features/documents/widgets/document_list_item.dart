import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/currency_formatter.dart';
import '../../../data/models/document_model.dart';

/// A single invoice/estimate row in the list.
class DocumentListItem extends StatelessWidget {
  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
  });

  final DocumentModel document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = document.derivedStatus;
    final statusStyle = _statusStyle(context, status);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.md),
        child: Row(
          children: [
            // Document type indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: Radii.cardAll,
              ),
              child: Icon(
                document.type == 'estimate'
                    ? Icons.description_outlined
                    : Icons.receipt_long_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Number + client name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.number,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.clientName ?? 'No client',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(
                      document.totalMinor, document.currencyCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                _StatusChip(status: status, style: statusStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyleData _statusStyle(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'paid':
        return _StatusStyleData(
          label: 'Paid',
          fg: isDark ? AppColorsDark.statusPaid : AppColorsLight.statusPaid,
          bg: isDark ? AppColorsDark.statusPaidSurface : AppColorsLight.statusPaidSurface,
        );
      case 'overdue':
        return _StatusStyleData(
          label: 'Overdue',
          fg: isDark ? AppColorsDark.statusOverdue : AppColorsLight.statusOverdue,
          bg: isDark ? AppColorsDark.statusOverdueSurface : AppColorsLight.statusOverdueSurface,
        );
      case 'draft':
        return _StatusStyleData(
          label: 'Draft',
          fg: isDark ? AppColorsDark.statusDraft : AppColorsLight.statusDraft,
          bg: isDark ? AppColorsDark.statusDraftSurface : AppColorsLight.statusDraftSurface,
        );
      case 'void':
        return _StatusStyleData(
          label: 'Void',
          fg: isDark ? AppColorsDark.statusDraft : AppColorsLight.statusDraft,
          bg: isDark ? AppColorsDark.statusDraftSurface : AppColorsLight.statusDraftSurface,
        );
      default: // sent
        return _StatusStyleData(
          label: 'Sent',
          fg: isDark ? AppColorsDark.statusSent : AppColorsLight.statusSent,
          bg: isDark ? AppColorsDark.statusSentSurface : AppColorsLight.statusSentSurface,
        );
    }
  }
}

class _StatusStyleData {
  const _StatusStyleData({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.style});

  final String status;
  final _StatusStyleData style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: Radii.chipAll,
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: style.fg),
      ),
    );
  }
}
