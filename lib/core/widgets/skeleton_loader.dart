import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.width, this.height = 16, this.borderRadius});

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outlineVariant;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _anim.value),
          borderRadius: widget.borderRadius ?? Radii.cardAll,
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: Row(
        children: [
          const SkeletonLoader(width: 40, height: 40, borderRadius: Radii.chipAll),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 14),
                const SizedBox(height: Spacing.xs),
                SkeletonLoader(width: MediaQuery.of(context).size.width * 0.4, height: 12),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          const SkeletonLoader(width: 60, height: 14),
        ],
      ),
    );
  }
}
