import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/exercise_type.dart';
import '../models/exercise_action.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Exercise> _todayExercises = [];
  List<ExerciseType> _exerciseTypes = [];
  List<ExerciseAction> _exerciseActions = [];
  DateTime _selectedDate = DateTime.now();

  List<Exercise> get todayExercises => _todayExercises;
  List<ExerciseType> get exerciseTypes => _exerciseTypes;
  List<ExerciseAction> get exerciseActions => _exerciseActions;
  DateTime get selectedDate => _selectedDate;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isSelectedPast {
    final sel = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return sel.isBefore(_today);
  }

  bool get canEdit => !isSelectedPast;

  WorkoutProvider() {
    _load();
  }

  void _load() {
    _exerciseTypes = DatabaseService.getAllTypes();
    _exerciseActions = DatabaseService.getAllActions();
    _refreshExercises();
  }

  void _refreshExercises() {
    _todayExercises = DatabaseService.getExercisesByDate(_selectedDate);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _refreshExercises();
  }

  // ── 添加训练 ───────────────────────────────────────────────
  Future<Exercise> addExercise({
    required ExerciseType type,
    required DateTime date,
    int? sets,
    int? reps,
    int? restSeconds,
    double? distance,
    String? actionId,
    String? actionName,
    DateTime? scheduledTime,
  }) async {
    final exercise = Exercise(
      id: _uuid.v4(),
      typeId: type.id,
      typeName: type.name,
      date: DateTime(date.year, date.month, date.day),
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      distance: distance,
      isStrength: type.isStrength,
      actionId: actionId,
      actionName: actionName,
      scheduledTime: scheduledTime,
    );
    await DatabaseService.saveExercise(exercise);
    _refreshExercises();
    return exercise;
  }

  // ── 编辑训练 ───────────────────────────────────────────────
  Future<void> editExercise({
    required Exercise exercise,
    int? sets,
    int? reps,
    int? restSeconds,
    double? distance,
    String? actionId,
    String? actionName,
    DateTime? scheduledTime,
  }) async {
    exercise.sets = sets;
    exercise.reps = reps;
    exercise.restSeconds = restSeconds;
    exercise.distance = distance;
    exercise.actionId = actionId;
    exercise.actionName = actionName;
    exercise.scheduledTime = scheduledTime;
    await DatabaseService.saveExercise(exercise);
    _refreshExercises();
  }

  // ── 更新训练（计时结束后保存） ─────────────────────────────
  Future<void> updateExercise(Exercise exercise) async {
    await DatabaseService.saveExercise(exercise);
    _refreshExercises();
  }

  // ── 删除训练 ───────────────────────────────────────────────
  Future<void> deleteExercise(String id) async {
    await DatabaseService.deleteExercise(id);
    _refreshExercises();
  }

  // ── 训练类型管理 ───────────────────────────────────────────
  Future<void> addCustomType(String name, ExerciseCategory category) async {
    final type = ExerciseType(
      id: _uuid.v4(),
      name: name,
      category: category,
      icon: category == ExerciseCategory.cardio ? 'e566' : 'ef5f',
      isCustom: true,
    );
    await DatabaseService.saveType(type);
    _exerciseTypes = DatabaseService.getAllTypes();
    notifyListeners();
  }

  Future<void> deleteCustomType(String id) async {
    await DatabaseService.deleteType(id);
    _exerciseTypes = DatabaseService.getAllTypes();
    notifyListeners();
  }

  // ── 动作库管理 ─────────────────────────────────────────────
  Future<void> addAction(String name) async {
    final action = ExerciseAction(id: _uuid.v4(), name: name, isBuiltIn: false);
    await DatabaseService.saveAction(action);
    _exerciseActions = DatabaseService.getAllActions();
    notifyListeners();
  }

  Future<void> editAction(ExerciseAction action, String newName) async {
    action.name = newName;
    await DatabaseService.saveAction(action);
    _exerciseActions = DatabaseService.getAllActions();
    notifyListeners();
  }

  Future<void> deleteAction(String id) async {
    await DatabaseService.deleteAction(id);
    _exerciseActions = DatabaseService.getAllActions();
    notifyListeners();
  }

  // ── 历史记录 ───────────────────────────────────────────────
  List<Exercise> getExercisesByDate(DateTime date) =>
      DatabaseService.getExercisesByDate(date);

  /// 过去 [days] 天内有训练记录的天数（不含今天）
  int getActiveDaysInPast(int days) {
    final counts = DatabaseService.getDailyCountsLastNDays(days + 1);
    final todayKey = () {
      final n = DateTime.now();
      return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    }();
    return counts.entries
        .where((e) => e.key != todayKey && e.value > 0)
        .length;
  }
}
