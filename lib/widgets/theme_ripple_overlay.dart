import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class ThemeRippleOverlay extends StatefulWidget {
  final Widget child;
  final ThemeProvider themeProvider;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const ThemeRippleOverlay({
    super.key,
    required this.child,
    required this.themeProvider,
    required this.lightTheme,
    required this.darkTheme,
  });

  @override
  State<ThemeRippleOverlay> createState() => _ThemeRippleOverlayState();
}

class _ThemeRippleOverlayState extends State<ThemeRippleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  Offset _origin = Offset.zero;
  bool _animating = false;
  Color _rippleColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    widget.themeProvider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    if (widget.themeProvider.isAnimating && !_ctrl.isAnimating) {
      // isDark 已是新值，圆的颜色 = 旧主题背景色
      _rippleColor = widget.themeProvider.isDark
          ? const Color(0xFFF2F4F7) // 旧主题是亮色
          : const Color(0xFF121212); // 旧主题是暗色
      _origin = widget.themeProvider.rippleOrigin ?? Offset.zero;
      setState(() => _animating = true);
      _ctrl.reverse(from: 1.0).then((_) {
        widget.themeProvider.onAnimationDone();
        if (mounted) setState(() => _animating = false);
      });
    }
  }

  @override
  void dispose() {
    widget.themeProvider.removeListener(_onProviderChange);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        if (!_animating) return widget.child;

        final size = MediaQuery.sizeOf(context);
        final maxRadius = [
          _origin.distance,
          Offset(_origin.dx, size.height - _origin.dy).distance,
          Offset(size.width - _origin.dx, _origin.dy).distance,
          Offset(size.width - _origin.dx, size.height - _origin.dy).distance,
        ].reduce(max);

        final t = Curves.easeOut.transform(_ctrl.value);
        final currentRadius = t * maxRadius;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              widget.child,
              CustomPaint(
                size: size,
                painter: _RipplePainter(
                  center: _origin,
                  radius: currentRadius,
                  color: _rippleColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  _RipplePainter({required this.center, required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.center != center || old.color != color;
}
