import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final String time;
  final Color color;
  final String? label;

  const TimerDisplay({
    super.key,
    required this.time,
    this.color = Colors.white,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: color.withAlpha(180),
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 80,
            fontWeight: FontWeight.w200,
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: -2,
            height: 1,
          ),
        ),
      ],
    );
  }
}
