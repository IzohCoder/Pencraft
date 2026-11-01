import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// A paper-like card surface.
/// Uses border (not shadow) by default; [paperDepth] adds a subtle 3-layer
/// shadow for document/preview surfaces.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.paperDepth = false,
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool paperDepth;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.cardColor;
    final radius = borderRadius ?? Radii.cardAll;
    final outline = theme.colorScheme.outlineVariant;
    final inkColor = theme.colorScheme.onSurface;

    final decoration = BoxDecoration(
      color: bg,
      borderRadius: radius,
      border: paperDepth ? null : Border.all(color: outline),
      boxShadow: paperDepth ? AppShadows.document(inkColor) : null,
    );

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: radius,
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
