import 'package:hive/hive.dart';

part 'exercise_type.g.dart';

@HiveType(typeId: 0)
enum ExerciseCategory {
  @HiveField(0)
  cardio, // 有氧

  @HiveField(1)
  strength, // 力量
}

@HiveType(typeId: 1)
class ExerciseType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  ExerciseCategory category;

  @HiveField(3)
  String icon; // icon codepoint as hex string

  @HiveField(4)
  bool isCustom;

  ExerciseType({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    this.isCustom = false,
  });

  bool get isCardio => category == ExerciseCategory.cardio;
  bool get isStrength => category == ExerciseCategory.strength;
}
