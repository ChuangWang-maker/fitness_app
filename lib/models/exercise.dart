import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 2)
enum ExerciseStatus {
  @HiveField(0)
  planned,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,
}

@HiveType(typeId: 3)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String typeId; // 关联 ExerciseType.id

  @HiveField(2)
  String typeName; // 冗余存储，方便展示

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  int durationSeconds; // 总时长（秒）

  @HiveField(5)
  double? distance; // 有氧专用（km）

  @HiveField(6)
  int? sets; // 力量：计划组数

  @HiveField(7)
  int? reps; // 力量：每组次数

  @HiveField(8)
  int? restSeconds; // 力量：组间休息（秒）

  @HiveField(9)
  int completedSets; // 力量：已完成组数

  @HiveField(10)
  ExerciseStatus status;

  @HiveField(11)
  bool isStrength;

  @HiveField(12)
  String? actionId;

  @HiveField(13)
  String? actionName;

  @HiveField(14)
  DateTime? scheduledTime;

  Exercise({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.date,
    this.durationSeconds = 0,
    this.distance,
    this.sets,
    this.reps,
    this.restSeconds,
    this.completedSets = 0,
    this.status = ExerciseStatus.planned,
    required this.isStrength,
    this.actionId,
    this.actionName,
    this.scheduledTime,
  });

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get displayName => actionName ?? typeName;

  String get formattedScheduledTime {
    if (scheduledTime == null) return '';
    final h = scheduledTime!.hour.toString().padLeft(2, '0');
    final m = scheduledTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
