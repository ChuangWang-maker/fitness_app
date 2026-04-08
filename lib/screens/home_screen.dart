import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/workout_provider.dart';
import '../models/exercise.dart';
import '../widgets/exercise_card.dart';
import '../widgets/wheel_date_picker.dart';
import '../app.dart';
import 'add_exercise_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 随机结果在 initState 里确定，不随 build 重跑
  late final int _motivationSeed;

  @override
  void initState() {
    super.initState();
    // 以当天日期为种子，同一天始终得到相同随机数，隔天自动换
    final now = DateTime.now();
    _motivationSeed = now.year * 10000 + now.month * 100 + now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            const threshold = 100.0;
            final v = details.primaryVelocity ?? 0;
            if (v < -threshold) {
              provider.selectDate(provider.selectedDate.add(const Duration(days: 1)));
            } else if (v > threshold) {
              provider.selectDate(provider.selectedDate.subtract(const Duration(days: 1)));
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(context, provider),
            body: _buildBody(context, provider),
            floatingActionButton: provider.canEdit
                ? FloatingActionButton.extended(
                    onPressed: () => _openAddExercise(context, provider),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      '添加训练',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, WorkoutProvider provider) {
    final now = provider.selectedDate;
    final today = DateTime.now();
    final isToday = _isSameDay(now, today);
    final isFuture = now.isAfter(DateTime(today.year, today.month, today.day));
    final dateStr = DateFormat('yyyy年M月d日').format(now);
    final weekDay = ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];

    String topLabel;
    if (isToday) {
      topLabel = '今天';
    } else if (isFuture) {
      topLabel = '计划 · 星期$weekDay';
    } else {
      topLabel = '星期$weekDay · 只读';
    }

    return AppBar(
      leading: const ThemeToggleButton(),
      title: Column(
        children: [
          Text(topLabel, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
          Text(dateStr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: '回到今天',
          onPressed: isToday ? null : () => provider.selectDate(DateTime.now()),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          tooltip: '选择日期',
          onPressed: () => _pickDate(context, provider),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WorkoutProvider provider) {
    final exercises = provider.todayExercises;

    Widget content;
    if (exercises.isEmpty) {
      content = _buildEmptyState(context, provider);
    } else {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildSummaryRow(context, exercises),
          const SizedBox(height: 16),
          ...exercises.map(
            (e) => ExerciseCard(
              exercise: e,
              readOnly: !provider.canEdit,
              onTap: () {
                if (provider.isSelectedPast) return;
                if (e.status == ExerciseStatus.completed) return;
                _openWorkout(context, e);
              },
              onEdit: () => _openEditExercise(context, provider, e),
              onDelete: () => _confirmDelete(context, provider, e),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildSummaryRow(BuildContext context, List<Exercise> exercises) {
    final completed = exercises.where((e) => e.status == ExerciseStatus.completed).length;
    final totalMin = exercises.fold<int>(0, (sum, e) => sum + e.durationSeconds) ~/ 60;
    final planned = exercises.where((e) => e.status == ExerciseStatus.planned).length;
    final inProgress = exercises.where((e) => e.status == ExerciseStatus.inProgress).length;
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            icon: Icons.check_circle_outline,
            value: '$completed / ${exercises.length}',
            label: '已完成',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            icon: Icons.timer_outlined,
            value: '${totalMin}min',
            label: '总时长',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            icon: Icons.pending_outlined,
            value: '${planned + inProgress}',
            label: '待完成',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WorkoutProvider provider) {
    final isPast = provider.isSelectedPast;
    final isToday = _isSameDay(provider.selectedDate, DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // 今天空状态：根据过去 14 天频次显示俏皮话
    if (isToday) {
      final activeDays = provider.getActiveDaysInPast(14);
      return _MotivationBanner(activeDays: activeDays, seed: _motivationSeed);
    }

    // 过去或未来：固定一句通用正能量话
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPast ? Icons.history : Icons.event_note_outlined,
              size: 64,
              color: primary.withAlpha(80),
            ),
            const SizedBox(height: 16),
            Text(
              isPast ? '这天没有训练记录' : '这天还没有训练计划',
              style: TextStyle(color: onSurface.withAlpha(130), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '每一次记录都是进步的痕迹，\n坚持就是最好的选择。',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withAlpha(80), fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WorkoutProvider provider) async {
    final picked = await showWheelDatePicker(
      context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) provider.selectDate(picked);
  }

  void _openAddExercise(BuildContext context, WorkoutProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExerciseScreen(initialDate: provider.selectedDate),
      ),
    );
  }

  void _openEditExercise(BuildContext context, WorkoutProvider provider, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExerciseScreen(
          initialDate: provider.selectedDate,
          editingExercise: exercise,
        ),
      ),
    );
  }

  void _openWorkout(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutScreen(exercise: exercise)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WorkoutProvider provider,
    Exercise exercise,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除训练'),
        content: Text('确定要删除「${exercise.displayName}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) provider.deleteExercise(exercise.id);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MotivationBanner extends StatelessWidget {
  final int activeDays;
  final int seed; // 由父级 State 固定，主题切换不变

  const _MotivationBanner({required this.activeDays, required this.seed});

  static const _neverPhrases = [
    ('还没开始呢，\n运动员证先收着？', '跑鞋还没开封，它在问你：「什么时候穿我？」'),
    ('你的肌肉已经\n开始发简历了……', '它们准备跳槽去别人的身体，快拦住它们！'),
    ('悄悄问一下，\n你知道健身是什么吗？', '没关系，今天是第零天，明天变第一天！'),
    ('运动记录：空空如也，\n像刚出厂的手机。', '来，装第一个 App——叫做「今天去练一练」。'),
    ('太空都有轨道，\n你的身材……自由飞翔中。', '给自己设一条运动轨道，从今天开始！'),
  ];

  static const _lazyPhrases = [
    ('好久不见，\n你还认识哑铃吗？', '它认识你，但它有点委屈，许久没被举起来了。'),
    ('运动细胞已经\n进入冬眠模式……', '要不要戳一戳，叫醒它们？'),
    ('上次锻炼到现在，\n地球都转了好多圈。', '要不跟着地球动一动？'),
    ('身体正在悄悄\n问候你的沙发……', '是时候让沙发暂时失业了！'),
    ('你最近的运动轨迹\n只有：床 → 椅子 → 床。', '今天加一个站点——运动！'),
  ];

  static const _normalPhrases = [
    ('今天的计划\n还没排上日程～', '先定个目标，动起来才是真的酷！'),
    ('空气都在等你\n挥一挥汗了～', '今天的训练计划，还差你的一个点击。'),
    ('今天的卡路里\n还没开始燃烧……', '点击下面的 ＋ 号，点燃今天！'),
    ('你的运动频率\n看起来还不错～', '再来一次？连续感才是最爽的！'),
    ('感觉今天也会是\n很棒的一天。', '加个训练，让它棒上加棒！'),
  ];

  static const _tooMuchPhrases = [
    ('哇，过去两周\n你练了好多次！', '记得给肌肉放个假，休息也是进步的一部分。'),
    ('你最近真的\n很拼！', '今天可以考虑轻松一下，身体需要时间修复哦。'),
    ('训练频率有点高，\n劳模本模了。', '适当的休息 = 下次练得更猛，来，躺平合法一天！'),
    ('你的肌肉发来申请：\n「请批准我今天休息」。', '休息不是偷懒，是让明天的你更强大！'),
    ('连续高频训练中……\n系统建议：充电 ing', '今天安排一个轻量或休息日，效果更好哦。'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    List<(String, String)> pool;
    IconData icon;
    if (activeDays == 0) {
      pool = _neverPhrases;
      icon = Icons.sentiment_dissatisfied_outlined;
    } else if (activeDays <= 3) {
      pool = _lazyPhrases;
      icon = Icons.sentiment_neutral_outlined;
    } else if (activeDays <= 9) {
      pool = _normalPhrases;
      icon = Icons.sentiment_satisfied_alt_outlined;
    } else {
      pool = _tooMuchPhrases;
      icon = Icons.sentiment_very_satisfied_outlined;
    }
    final picked = pool[seed % pool.length];
    final quote = picked.$1;
    final sub = picked.$2;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: primary.withAlpha(100)),
                  const SizedBox(height: 20),
                  Text(
                    quote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withAlpha(140),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '↓ 点击下方按钮开始今天的训练',
                    style: TextStyle(
                      color: primary.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: onSurface.withAlpha(120),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
