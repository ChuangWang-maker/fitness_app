import 'package:hive/hive.dart';

part 'exercise_action.g.dart';

@HiveType(typeId: 4)
class ExerciseAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isBuiltIn;

  ExerciseAction({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
  });
}
