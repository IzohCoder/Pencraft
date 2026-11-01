import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Template chooser — lets user pick among the 3 PDF templates.
/// Shown as a modal bottom sheet from document creation or detail screen.
class TemplateChooserScreen extends StatelessWidget {
  const TemplateChooserScreen({
    super.key,
    required this.currentTemplateId,
    required this.onSelected,
  });

  final int currentTemplateId;
  final ValueChanged<int> onSelected;

  static Future<int?> show(BuildContext context, {required int current}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplateChooserScreen(
        currentTemplateId: current,
        onSelected: (id) => Navigator.of(context).pop(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text('Choose template', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Text(
            'All templates are fully customised by your business colours.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.lg),
          // Template cards
          _TemplateCard(
            id: 1,
            name: 'Classic Ledger',
            description:
                'Warm cream paper, serif headings, a timeless paper-ledger feel.',
            icon: Icons.menu_book_outlined,
            isSelected: currentTemplateId == 1,
            onTap: () => onSelected(1),
          ),
          const SizedBox(height: Spacing.sm),
          _TemplateCard(
            id: 2,
            name: 'Print Studio',
            description:
                'Bold accent header band, crisp white body — print-ready and modern.',
            icon: Icons.print_outlined,
            isSelected: currentTemplateId == 2,
            onTap: () => onSelected(2),
          ),
          const SizedBox(height: Spacing.sm),
          _TemplateCard(
            id: 3,
            name: 'Field Receipt',
            description:
                'Narrow, compact, fast — perfect for tradespeople and quick jobs.',
            icon: Icons.receipt_outlined,
            isSelected: currentTemplateId == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final int id;
  final String name;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: Radii.cardBR,
      child: AnimatedContainer(
        duration: Motion.short,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: Radii.cardBR,
          border: Border.all(
            color: isSelected ? accent : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? accent : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: isSelected ? accent : null,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}
