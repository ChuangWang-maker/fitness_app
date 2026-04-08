import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../models/exercise.dart';

enum TrainingPhase { idle, training, rest, paused, completed }

class TimerProvider extends ChangeNotifier {
  // ── 状态 ───────────────────────────────────────────────────
  TrainingPhase _phase = TrainingPhase.idle;
  TrainingPhase _pausedFrom = TrainingPhase.idle;

  Exercise? _exercise;
  int _currentSet = 1;
  int _elapsedSeconds = 0; // 训练总计时（秒）
  int _restRemaining = 0; // 当前休息剩余（秒）

  Timer? _timer;

  // ── Getters ────────────────────────────────────────────────
  TrainingPhase get phase => _phase;
  Exercise? get exercise => _exercise;
  int get currentSet => _currentSet;
  int get totalSets => _exercise?.sets ?? 1;
  int get elapsedSeconds => _elapsedSeconds;
  int get restRemaining => _restRemaining;

  bool get isIdle => _phase == TrainingPhase.idle;
  bool get isTraining => _phase == TrainingPhase.training;
  bool get isRest => _phase == TrainingPhase.rest;
  bool get isPaused => _phase == TrainingPhase.paused;
  bool get isCompleted => _phase == TrainingPhase.completed;

  String get elapsedFormatted {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get restFormatted {
    final m = _restRemaining ~/ 60;
    final s = _restRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── 初始化训练 ─────────────────────────────────────────────
  void initExercise(Exercise exercise) {
    _reset();
    _exercise = exercise;
    notifyListeners();
  }

  // ── 开始 ───────────────────────────────────────────────────
  void start() {
    if (_phase == TrainingPhase.idle) {
      _phase = TrainingPhase.training;
      _startTick();
    }
    notifyListeners();
  }

  // ── 暂停 / 继续 ────────────────────────────────────────────
  void pauseOrResume() {
    if (_phase == TrainingPhase.paused) {
      _phase = _pausedFrom;
      _startTick();
    } else if (_phase == TrainingPhase.training ||
        _phase == TrainingPhase.rest) {
      _pausedFrom = _phase;
      _phase = TrainingPhase.paused;
      _timer?.cancel();
    }
    notifyListeners();
  }

  // ── 完成当前组（力量专用） ─────────────────────────────────
  void completeSet() {
    if (_phase != TrainingPhase.training) return;
    _timer?.cancel();

    final ex = _exercise!;
    if (_currentSet >= (ex.sets ?? 1)) {
      // 最后一组，结束训练
      _finishTraining();
    } else {
      // 进入休息倒计时
      _currentSet++;
      _restRemaining = ex.restSeconds ?? 60;
      _phase = TrainingPhase.rest;
      _startTick();
      _vibrate();
    }
    notifyListeners();
  }

  // ── 跳过休息 ───────────────────────────────────────────────
  void skipRest() {
    if (_phase != TrainingPhase.rest) return;
    _timer?.cancel();
    _phase = TrainingPhase.training;
    _startTick();
    notifyListeners();
  }

  // ── 有氧：手动结束 ─────────────────────────────────────────
  void stopCardio() {
    _timer?.cancel();
    _finishTraining();
    notifyListeners();
  }

  // ── 中途结束并保存（不跳转完成页） ────────────────────────
  void finishNow() {
    _timer?.cancel();
    _exercise?.durationSeconds = _elapsedSeconds;
    _exercise?.status = ExerciseStatus.completed;
    _exercise?.completedSets = _currentSet;
  }

  // ── 内部：结束训练 ─────────────────────────────────────────
  void _finishTraining() {
    _phase = TrainingPhase.completed;
    _exercise?.durationSeconds = _elapsedSeconds;
    _exercise?.status = ExerciseStatus.completed;
    _exercise?.completedSets = _currentSet;
    _vibrate(times: 3);
  }

  // ── Tick 计时 ──────────────────────────────────────────────
  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase == TrainingPhase.training) {
        _elapsedSeconds++;
      } else if (_phase == TrainingPhase.rest) {
        if (_restRemaining > 0) {
          _restRemaining--;
        } else {
          // 倒计时结束，自动进入下一组训练
          _timer?.cancel();
          _phase = TrainingPhase.training;
          _startTick();
          _vibrate();
        }
      }
      notifyListeners();
    });
  }

  // ── 震动 ───────────────────────────────────────────────────
  Future<void> _vibrate({int times = 1}) async {
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator) return;
      if (times == 1) {
        Vibration.vibrate(duration: 300);
      } else {
        // 多次震动：用 pattern 实现，格式 [等待,震动,等待,震动,...]
        final pattern = <int>[];
        for (int i = 0; i < times; i++) {
          pattern.add(i == 0 ? 0 : 200); // 间隔
          pattern.add(300); // 震动时长
        }
        Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {
      // 震动失败不影响训练流程
    }
  }

  // ── 重置 ───────────────────────────────────────────────────
  void _reset() {
    _timer?.cancel();
    _phase = TrainingPhase.idle;
    _exercise = null;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _restRemaining = 0;
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
