import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_colors.dart';

/// Rubber stamp "PAID" animation overlay.
/// Drops from above with spring physics, rotates slightly, ink desaturates.
/// Trigger by inserting into a Stack and removing after 2 seconds.
class PaidStampOverlay extends StatefulWidget {
  const PaidStampOverlay({super.key});

  @override
  State<PaidStampOverlay> createState() => _PaidStampOverlayState();
}

class _PaidStampOverlayState extends State<PaidStampOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Spring-like: overshoot slightly then settle
    _scaleAnim = Tween<double>(begin: 1.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _rotateAnim = Tween<double>(begin: -0.14, end: -0.14).animate(_ctrl); // fixed -8°

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Haptic fires immediately
    HapticFeedback.heavyImpact();

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Transform.rotate(
                  angle: _rotateAnim.value,
                  child: child,
                ),
              ),
            ),
            child: _StampMark(),
          ),
        ),
      ),
    );
  }
}

class _StampMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stampColor = AppColorsLight.accent;

    return Container(
      width: 180,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: stampColor, width: 4),
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Top serration
          Positioned.fill(
            child: CustomPaint(painter: _StampBorderPainter(color: stampColor)),
          ),
          Center(
            child: Text(
              'PAID',
              style: TextStyle(
                fontFamily: 'DMSerifDisplay',
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: stampColor,
                letterSpacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StampBorderPainter extends CustomPainter {
  const _StampBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Decorative corners
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerSize = 12.0;
    // Top-left
    canvas.drawLine(Offset(8, 8 + cornerSize), const Offset(8, 8), paint);
    canvas.drawLine(const Offset(8, 8), Offset(8 + cornerSize, 8), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - 8, 8 + cornerSize),
        Offset(size.width - 8, 8), paint);
    canvas.drawLine(Offset(size.width - 8, 8),
        Offset(size.width - 8 - cornerSize, 8), paint);
    // Bottom-left
    canvas.drawLine(Offset(8, size.height - 8 - cornerSize),
        Offset(8, size.height - 8), paint);
    canvas.drawLine(Offset(8, size.height - 8),
        Offset(8 + cornerSize, size.height - 8), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - 8, size.height - 8 - cornerSize),
        Offset(size.width - 8, size.height - 8), paint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8),
        Offset(size.width - 8 - cornerSize, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
