import 'package:hive/hive.dart';
import '../models/exercise_type.dart';
import '../models/exercise.dart';
import '../models/exercise_action.dart';

class DatabaseService {
  static const _typeBoxName = 'exercise_types';
  static const _exerciseBoxName = 'exercises';
  static const _actionBoxName = 'exercise_actions';

  static late Box<ExerciseType> _typeBox;
  static late Box<Exercise> _exerciseBox;
  static late Box<ExerciseAction> _actionBox;

  static Future<void> init() async {
    _typeBox = await Hive.openBox<ExerciseType>(_typeBoxName);
    _exerciseBox = await Hive.openBox<Exercise>(_exerciseBoxName);
    _actionBox = await Hive.openBox<ExerciseAction>(_actionBoxName);
    _seedDefaultTypes();
    _seedDefaultActions();
  }

  // ── 默认训练类型 ──────────────────────────────────────────
  static void _seedDefaultTypes() {
    if (_typeBox.isNotEmpty) return;
    final defaults = [
      ExerciseType(
        id: 'running',
        name: '跑步',
        category: ExerciseCategory.cardio,
        icon: 'e566',
      ),
      ExerciseType(
        id: 'cycling',
        name: '骑行',
        category: ExerciseCategory.cardio,
        icon: 'e1a0',
      ),
      ExerciseType(
        id: 'strength',
        name: '力量训练',
        category: ExerciseCategory.strength,
        icon: 'ef5f',
      ),
    ];
    for (final t in defaults) {
      _typeBox.put(t.id, t);
    }
  }

  // ── 默认力量动作 ──────────────────────────────────────────
  static void _seedDefaultActions() {
    if (_actionBox.isNotEmpty) return;
    final defaults = [
      ExerciseAction(id: 'pushup', name: '俯卧撑', isBuiltIn: true),
      ExerciseAction(id: 'squat', name: '深蹲', isBuiltIn: true),
      ExerciseAction(id: 'pullup', name: '引体向上', isBuiltIn: true),
      ExerciseAction(id: 'benchpress', name: '卧推', isBuiltIn: true),
      ExerciseAction(id: 'deadlift', name: '硬拉', isBuiltIn: true),
      ExerciseAction(id: 'curl', name: '哑铃弯举', isBuiltIn: true),
      ExerciseAction(id: 'plank', name: '平板支撑', isBuiltIn: true),
      ExerciseAction(id: 'lunge', name: '弓步蹲', isBuiltIn: true),
    ];
    for (final a in defaults) {
      _actionBox.put(a.id, a);
    }
  }

  // ── ExerciseType CRUD ──────────────────────────────────────
  static List<ExerciseType> getAllTypes() => _typeBox.values.toList();

  static Future<void> saveType(ExerciseType type) =>
      _typeBox.put(type.id, type);

  static Future<void> deleteType(String id) => _typeBox.delete(id);

  // ── ExerciseAction CRUD ────────────────────────────────────
  static List<ExerciseAction> getAllActions() => _actionBox.values.toList();

  static Future<void> saveAction(ExerciseAction action) =>
      _actionBox.put(action.id, action);

  static Future<void> deleteAction(String id) => _actionBox.delete(id);

  // ── Exercise CRUD ──────────────────────────────────────────
  static List<Exercise> getAllExercises() => _exerciseBox.values.toList();

  static List<Exercise> getExercisesByDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _exerciseBox.values.where((e) => e.dateKey == key).toList()
      ..sort((a, b) {
        final at = a.scheduledTime;
        final bt = b.scheduledTime;
        if (at != null && bt != null) return at.compareTo(bt);
        return a.date.compareTo(b.date);
      });
  }

  static Future<void> saveExercise(Exercise exercise) =>
      _exerciseBox.put(exercise.id, exercise);

  static Future<void> deleteExercise(String id) => _exerciseBox.delete(id);

  // ── 统计查询 ───────────────────────────────────────────────
  static int getWeeklyCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _exerciseBox.values
        .where(
          (e) =>
              e.status == ExerciseStatus.completed &&
              e.date.isAfter(start.subtract(const Duration(seconds: 1))),
        )
        .length;
  }

  static Map<String, int> getTotalDurationByType() {
    final result = <String, int>{};
    for (final e in _exerciseBox.values) {
      if (e.status == ExerciseStatus.completed) {
        result[e.typeName] = (result[e.typeName] ?? 0) + e.durationSeconds;
      }
    }
    return result;
  }

  static Map<String, int> getDailyCountsLastNDays(int n) {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = n - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      result[key] = 0;
    }
    for (final e in _exerciseBox.values) {
      if (e.status == ExerciseStatus.completed &&
          result.containsKey(e.dateKey)) {
        result[e.dateKey] = result[e.dateKey]! + 1;
      }
    }
    return result;
  }

  static Set<String> getAllRecordedDates() {
    return _exerciseBox.values
        .where((e) => e.status == ExerciseStatus.completed)
        .map((e) => e.dateKey)
        .toSet();
  }

  /// 有计划（planned）的日期，用于历史日历标记未来计划
  static Set<String> getAllPlannedDates() {
    return _exerciseBox.values
        .where((e) => e.status == ExerciseStatus.planned)
        .map((e) => e.dateKey)
        .toSet();
  }

  /// 累计完成训练总次数
  static int getTotalCompletedCount() {
    return _exerciseBox.values
        .where((e) => e.status == ExerciseStatus.completed)
        .length;
  }

  /// 当前连续打卡天数
  static int getStreakDays() {
    final completedDates = _exerciseBox.values
        .where((e) => e.status == ExerciseStatus.completed)
        .map((e) => e.dateKey)
        .toSet();
    if (completedDates.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i <= 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (completedDates.contains(key)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  /// 最近完成的 N 条训练
  static List<Exercise> getRecentCompleted(int n) {
    final list = _exerciseBox.values
        .where((e) => e.status == ExerciseStatus.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.take(n).toList();
  }
}
