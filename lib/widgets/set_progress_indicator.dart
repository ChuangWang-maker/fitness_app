import 'package:flutter/material.dart';

class SetProgressIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;

  const SetProgressIndicator({
    super.key,
    required this.currentSet,
    required this.totalSets,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Text(
          '第 $currentSet 组 / 共 $totalSets 组',
          style: TextStyle(
            color: onSurface.withAlpha(150),
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSets, (i) {
            final done = i < currentSet - 1;
            final current = i == currentSet - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: current ? 28 : 16,
              height: 6,
              decoration: BoxDecoration(
                color: done
                    ? primaryColor
                    : current
                    ? primaryColor
                    : onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
