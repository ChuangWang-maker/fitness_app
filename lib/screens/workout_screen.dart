import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/timer_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/timer_display.dart';
import '../widgets/set_progress_indicator.dart';

class WorkoutScreen extends StatefulWidget {
  final Exercise exercise;

  const WorkoutScreen({super.key, required this.exercise});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimerProvider>().initExercise(widget.exercise);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        final isRest = timer.isRest;
        final bgColor = Theme.of(context).scaffoldBackgroundColor;
        final accentColor = isRest
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) await _onWillPop(context, timer);
          },
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              title: Text(widget.exercise.typeName),
              backgroundColor: bgColor,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _onWillPop(context, timer),
              ),
            ),
            body: SafeArea(
              child: timer.isCompleted
                  ? _buildCompletedView(context, timer)
                  : _buildActiveView(context, timer, accentColor),
            ),
          ),
        );
      },
    );
  }

  // ── 训练进行中 ─────────────────────────────────────────────
  Widget _buildActiveView(
    BuildContext context,
    TimerProvider timer,
    Color accentColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 状态标签
              _buildPhaseLabel(timer, accentColor),
              const SizedBox(height: 24),

              // 大号计时器
              TimerDisplay(
                time: timer.isRest
                    ? timer.restFormatted
                    : timer.elapsedFormatted,
                color: accentColor,
                label: timer.isRest ? '休息倒计时' : '训练计时',
              ),

              const SizedBox(height: 32),

              // 力量训练：组数进度
              if (widget.exercise.isStrength)
                SetProgressIndicator(
                  currentSet: timer.currentSet,
                  totalSets: timer.totalSets,
                ),

              // 有氧训练：数据展示
              if (!widget.exercise.isStrength &&
                  widget.exercise.distance != null)
                _buildCardioInfo(accentColor),
            ],
          ),
        ),

        // 底部按钮区
        _buildBottomButtons(context, timer, accentColor),
      ],
    );
  }

  Widget _buildPhaseLabel(TimerProvider timer, Color color) {
    String text;
    if (timer.isIdle) {
      text = '准备开始';
    } else if (timer.isTraining) {
      text = '训练中';
    } else if (timer.isRest) {
      text = '休息中';
    } else if (timer.isPaused) {
      text = '已暂停';
    } else {
      text = '';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCardioInfo(Color accentColor) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          '目标距离：${widget.exercise.distance!.toStringAsFixed(1)} km',
          style: TextStyle(color: accentColor.withAlpha(200), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    TimerProvider timer,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        children: [
          // 力量训练：完成本组 / 跳过休息
          if (widget.exercise.isStrength) ...[
            if (timer.isTraining)
              ElevatedButton(
                onPressed: timer.completeSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size.fromHeight(64),
                ),
                child: Text(
                  timer.currentSet >= timer.totalSets
                      ? '完成最后一组'
                      : '完成本组（第${timer.currentSet}组）',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            if (timer.isPaused)
              ElevatedButton(
                onPressed: () => _confirmStop(context, timer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size.fromHeight(64),
                ),
                child: const Text(
                  '结束训练',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            if (timer.isRest)
              ElevatedButton(
                onPressed: timer.skipRest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  minimumSize: const Size.fromHeight(64),
                ),
                child: const Text(
                  '跳过休息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // 有氧训练：结束
          if (!widget.exercise.isStrength && (timer.isTraining || timer.isPaused)) ...[
            ElevatedButton(
              onPressed: () => _confirmStop(context, timer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('结束训练', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
          ],

          // 开始按钮（idle 状态）
          if (timer.isIdle)
            ElevatedButton.icon(
              onPressed: timer.start,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('开始训练', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: const Size.fromHeight(64),
              ),
            ),

          // 暂停 / 继续（非idle、非completed）
          if (!timer.isIdle && !timer.isCompleted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: timer.pauseOrResume,
                icon: Icon(timer.isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(timer.isPaused ? '继续' : '暂停'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 完成页面 ───────────────────────────────────────────────
  Widget _buildCompletedView(BuildContext context, TimerProvider timer) {
    final ex = timer.exercise!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 88,
            ),
            const SizedBox(height: 24),
            const Text(
              '训练完成！',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildResultCard(context, ex),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _saveAndExit(context, timer),
              child: const Text('保存并退出', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Exercise ex) {
    final items = <Map<String, String>>[
      {'label': '总时长', 'value': ex.formattedDuration},
      if (ex.isStrength)
        {'label': '完成组数', 'value': '${ex.completedSets} / ${ex.sets} 组'},
      if (ex.isStrength)
        {'label': '每组次数', 'value': '${ex.reps} 次'},
      if (!ex.isStrength && ex.distance != null)
        {'label': '距离', 'value': '${ex.distance!.toStringAsFixed(1)} km'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['label']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  fontSize: 14,
                ),
              ),
              Text(
                item['value']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context, TimerProvider timer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束训练？'),
        content: const Text('将保存当前训练进度并退出。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (ok == true) {
      timer.finishNow();
      await _saveAndExit(context, timer);
    }
  }

  Future<void> _onWillPop(BuildContext context, TimerProvider timer) async {
    if (timer.isIdle || timer.isCompleted) {
      timer.reset();
      Navigator.pop(context);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出训练？'),
        content: const Text('训练记录将不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续训练'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      timer.reset();
      if (context.mounted) Navigator.pop(context);
    }
    return;
  }

  Future<void> _saveAndExit(BuildContext context, TimerProvider timer) async {
    final ex = timer.exercise;
    if (ex != null) {
      await context.read<WorkoutProvider>().updateExercise(ex);
    }
    timer.reset();
    if (context.mounted) Navigator.pop(context);
  }
}
