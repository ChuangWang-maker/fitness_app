import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool readOnly;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.readOnly = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = exercise.status == ExerciseStatus.completed;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? primaryColor.withAlpha(100) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              _buildIcon(context, isCompleted),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo(context, isCompleted)),
              if (!readOnly)
                _buildMenu(context)
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                  size: 16,
                ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, bool isCompleted) {
    final color = isCompleted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withAlpha(100);
    IconData icon;
    if (exercise.isStrength) {
      icon = Icons.fitness_center;
    } else if (exercise.typeName == '跑步') {
      icon = Icons.directions_run;
    } else if (exercise.typeName == '骑行') {
      icon = Icons.directions_bike;
    } else {
      icon = Icons.directions_run; // 自定义有氧类型通用图标
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildInfo(BuildContext context, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                exercise.displayName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (exercise.isStrength && exercise.actionName != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise.typeName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _buildSubtitle(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            fontSize: 12,
          ),
        ),
        if (exercise.scheduledTime != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 12,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                exercise.formattedScheduledTime,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        if (isCompleted && exercise.durationSeconds > 0) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.check_circle, size: 12,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '用时 ${exercise.formattedDuration}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: onSurface.withAlpha(120), size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: onSurface.withAlpha(200)),
              const SizedBox(width: 10),
              Text('编辑', style: TextStyle(color: onSurface)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('删除', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  String _buildSubtitle() {
    if (exercise.isStrength) {
      final sets = exercise.sets ?? 0;
      final reps = exercise.reps ?? 0;
      final rest = exercise.restSeconds ?? 60;
      return '$sets组 × $reps次 · 休息$rest秒';
    } else {
      final dist = exercise.distance;
      return dist != null ? '目标 ${dist.toStringAsFixed(1)} km' : '有氧训练';
    }
  }
}
