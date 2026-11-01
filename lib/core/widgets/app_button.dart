import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = enabled && !isLoading && onPressed != null;

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(context),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: Spacing.sm),
                  Text(label),
                ],
              )
            : Text(label);

    final size = expand
        ? const Size(double.infinity, TouchTargets.minimum)
        : const Size(0, TouchTargets.minimum);

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(minimumSize: size),
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(minimumSize: size),
          child: child,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(minimumSize: size),
          child: child,
        );
      case AppButtonVariant.destructive:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: child,
        );
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return Theme.of(context).colorScheme.onPrimary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
