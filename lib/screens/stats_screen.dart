import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../app.dart';

// ── 颜色常量（有氧/力量区分） ─────────────────────────────────
const _cardioColor = Color(0xFF1976D2);
const _strengthColor = Color(0xFFFF6D00);
const _otherColor = Color(0xFF43A047);

Color _typeColor(Exercise e) {
  if (e.isStrength) return _strengthColor;
  if (e.typeName == '跑步' || e.typeName == '骑行') return _cardioColor;
  return _otherColor;
}

Color _typeColorByName(String name, Map<String, bool> strengthMap) {
  if (strengthMap[name] == true) return _strengthColor;
  return _cardioColor;
}

// ── 主页面 ────────────────────────────────────────────────────
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late Animation<double> _heroAnim;

  // 数据
  late int _streak;
  late int _totalCount;
  late int _totalSeconds;
  late int _weeklyCount;
  late Map<String, int> _daily14; // 近14天 dateKey→count
  late Map<String, int> _durationByType;
  late Map<String, bool> _isStrengthByType;
  late List<Exercise> _recentList;
  late int _weeklyTarget;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heroAnim = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic);
    _loadData(); // initState 里 didChangeDependencies 还没跑，先同步加载一次
    _heroCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<WorkoutProvider>();
    _loadData();
  }

  void _loadData() {
    _streak = DatabaseService.getStreakDays();
    _totalCount = DatabaseService.getTotalCompletedCount();
    _weeklyCount = DatabaseService.getWeeklyCount();
    _durationByType = DatabaseService.getTotalDurationByType();
    _totalSeconds = _durationByType.values.fold(0, (s, v) => s + v);
    _daily14 = DatabaseService.getDailyCountsLastNDays(14);
    _recentList = DatabaseService.getRecentCompleted(20);
    _weeklyTarget = 5;
    _isStrengthByType = {};
    for (final e in _recentList) {
      _isStrengthByType[e.typeName] = e.isStrength;
    }
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: const ThemeToggleButton(),
        title: const Text('训练统计'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // ① 英雄区
          _HeroCard(
            streak: _streak,
            totalCount: _totalCount,
            totalSeconds: _totalSeconds,
            animation: _heroAnim,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // ② 本周进度
          _WeeklyProgress(
            current: _weeklyCount,
            target: _weeklyTarget,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // ③ 近14天热力图
          _SectionTitle(title: '近14天训练'),
          const SizedBox(height: 10),
          _HeatmapGrid(daily14: _daily14, isDark: isDark),
          const SizedBox(height: 20),

          // ④ 各类型环形分布
          if (_durationByType.isNotEmpty) ...[
            _SectionTitle(title: '训练类型分布'),
            const SizedBox(height: 10),
            _DonutChart(
              durationByType: _durationByType,
              isStrengthByType: _isStrengthByType,
              totalSeconds: _totalSeconds,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],

          // ⑤ 训练故事流
          if (_recentList.isNotEmpty) ...[
            _SectionTitle(title: '训练记录'),
            const SizedBox(height: 10),
            _StoryTimeline(exercises: _recentList),
          ],
        ],
      ),
    );
  }
}

// ── ① 英雄区 ──────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final int streak;
  final int totalCount;
  final int totalSeconds;
  final Animation<double> animation;
  final bool isDark;

  const _HeroCard({
    required this.streak,
    required this.totalCount,
    required this.totalSeconds,
    required this.animation,
    required this.isDark,
  });

  String _fmtSeconds(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // 主角：streak>0 显示连续打卡，否则显示总次数
    final heroValue = streak > 0 ? streak : totalCount;
    final heroLabel = streak > 0 ? '天连续打卡' : '次累计训练';
    final heroIcon = streak > 0 ? '🔥' : '💪';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFBF360C), const Color(0xFFE64A19)]
              : [const Color(0xFFFF6D00), const Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(isDark ? 60 : 80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$heroIcon  连续打卡',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final displayed = (heroValue * animation.value).round();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$displayed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      heroLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                label: '累计训练',
                value: '$totalCount 次',
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              _HeroStat(
                label: '总时长',
                value: _fmtSeconds(totalSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── ② 本周进度 ────────────────────────────────────────────────
class _WeeklyProgress extends StatelessWidget {
  final int current;
  final int target;
  final bool isDark;

  const _WeeklyProgress({
    required this.current,
    required this.target,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final ratio = (current / target).clamp(0.0, 1.0);
    final done = current >= target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周目标',
                style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              Row(
                children: [
                  if (done)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('🎉', style: TextStyle(fontSize: 14)),
                    ),
                  Text(
                    '$current / $target 次',
                    style: TextStyle(
                        color: done ? primary : onSurface.withAlpha(160),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: onSurface.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(
                    done ? const Color(0xFF43A047) : primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done
                ? '本周目标已完成，继续保持！'
                : '还差 ${target - current} 次完成本周目标',
            style:
                TextStyle(color: onSurface.withAlpha(120), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── ③ 近14天热力图 ────────────────────────────────────────────
class _HeatmapGrid extends StatefulWidget {
  final Map<String, int> daily14;
  final bool isDark;

  const _HeatmapGrid({required this.daily14, required this.isDark});

  @override
  State<_HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends State<_HeatmapGrid> {
  String? _tappedKey;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final entries = widget.daily14.entries.toList();
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 星期标题行
          Row(
            children: weekLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: onSurface.withAlpha(80),
                                fontSize: 10)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // 方块网格（两行，每行7个）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry = entries[i];
              final count = entry.value;
              // 固定4档：0=空，1次=浅，2次=中，3+次=深
              final alpha = count == 0
                  ? (widget.isDark ? 18 : 15)
                  : count == 1
                      ? 70
                      : count == 2
                          ? 150
                          : 230;
              final isTapped = _tappedKey == entry.key;

              // 解析日期
              final parts = entry.key.split('-');
              final date = DateTime(
                  int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              final isToday = () {
                final now = DateTime.now();
                return date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              }();

              return GestureDetector(
                onTap: () => setState(
                    () => _tappedKey = isTapped ? null : entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: count == 0
                        ? onSurface.withAlpha(widget.isDark ? 18 : 15)
                        : primary.withAlpha(alpha),
                    borderRadius: BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: primary, width: 1.5)
                        : null,
                  ),
                  child: isTapped && count > 0
                      ? Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
          // 点击后的提示
          if (_tappedKey != null) ...[
            const SizedBox(height: 8),
            Builder(builder: (ctx) {
              final parts = _tappedKey!.split('-');
              final date = DateTime(int.parse(parts[0]),
                  int.parse(parts[1]), int.parse(parts[2]));
              final count = widget.daily14[_tappedKey] ?? 0;
              return Text(
                '${DateFormat('M月d日 E', 'zh_CN').format(date)}  ·  '
                '${count == 0 ? '休息日' : '完成 $count 次训练'}',
                style: TextStyle(
                    color: onSurface.withAlpha(140), fontSize: 11),
              );
            }),
          ],
          const SizedBox(height: 6),
          // 图例
          Row(
            children: [
              Text('少',
                  style: TextStyle(
                      color: onSurface.withAlpha(80), fontSize: 10)),
              const SizedBox(width: 4),
              ...List.generate(
                  4,
                  (i) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: primary
                              .withAlpha([20, 80, 140, 220][i]),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
              Text('多',
                  style: TextStyle(
                      color: onSurface.withAlpha(80), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ④ 环形分布图 ──────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final Map<String, int> durationByType;
  final Map<String, bool> isStrengthByType;
  final int totalSeconds;
  final bool isDark;

  const _DonutChart({
    required this.durationByType,
    required this.isStrengthByType,
    required this.totalSeconds,
    required this.isDark,
  });

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h${m}m';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;

    // 分配颜色（不依赖 isStrength，用固定调色板）
    final palette = [
      _strengthColor,
      _cardioColor,
      _otherColor,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    final entries = durationByType.entries.toList();
    final colors = List.generate(
        entries.length, (i) => palette[i % palette.length]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(
        children: [
          // 环形图
          SizedBox(
            width: 130,
            height: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, progress, __) => CustomPaint(
                painter: _DonutPainter(
                  entries: entries,
                  colors: colors,
                  total: totalSeconds,
                  progress: progress,
                  isDark: isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmt(totalSeconds),
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '总时长',
                        style: TextStyle(
                            color: onSurface.withAlpha(120),
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 图例
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final pct = totalSeconds > 0
                    ? (e.value / totalSeconds * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                              color: onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                            color: colors[i],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final List<Color> colors;
  final int total;
  final double progress;
  final bool isDark;

  _DonutPainter({
    required this.entries,
    required this.colors,
    required this.total,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 18.0;
    const startAngle = -pi / 2;

    if (total == 0) return;

    double swept = 0;
    for (int i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * pi * progress;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + swept,
        sweep - 0.04, // 小间隔
        false,
        paint,
      );
      swept += sweep;
    }

    // 背景轨道
    if (progress < 1) {
      final bgPaint = Paint()
        ..color =
            (isDark ? Colors.white : Colors.black).withAlpha(15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + swept,
        2 * pi * progress - swept + 2 * pi * (1 - progress),
        false,
        bgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.total != total;
}

// ── ⑤ 训练故事流时间轴 ───────────────────────────────────────
class _StoryTimeline extends StatefulWidget {
  final List<Exercise> exercises;

  const _StoryTimeline({required this.exercises});

  @override
  State<_StoryTimeline> createState() => _StoryTimelineState();
}

class _StoryTimelineState extends State<_StoryTimeline> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    // 按日期分组
    final grouped = <String, List<Exercise>>{};
    for (final e in widget.exercises) {
      final key = e.dateKey;
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final displayKeys =
        _expanded ? sortedKeys : sortedKeys.take(5).toList();

    return Column(
      children: [
        ...displayKeys.asMap().entries.map((entry) {
          final i = entry.key;
          final key = entry.value;
          final exercises = grouped[key]!;
          final parts = key.split('-');
          final date = DateTime(int.parse(parts[0]),
              int.parse(parts[1]), int.parse(parts[2]));
          final isLast = i == displayKeys.length - 1;

          return _TimelineDay(
            date: date,
            exercises: exercises,
            isLast: isLast,
          );
        }),
        if (sortedKeys.length > 5) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                border:
                    Border.all(color: onSurface.withAlpha(40)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? '收起'
                        : '查看更多（共${sortedKeys.length}天）',
                    style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineDay extends StatelessWidget {
  final DateTime date;
  final List<Exercise> exercises;
  final bool isLast;

  const _TimelineDay({
    required this.date,
    required this.exercises,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String dateLabel;
    if (isToday) {
      dateLabel = '今天';
    } else if (isYesterday) {
      dateLabel = '昨天';
    } else {
      dateLabel = DateFormat('M月d日 E', 'zh_CN').format(date);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧时间轴
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: primary.withAlpha(80),
                          blurRadius: 6,
                          spreadRadius: 1)
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: primary.withAlpha(40),
                    ),
                  ),
              ],
            ),
          ),
          // 右侧内容
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 0),
                    child: Text(
                      dateLabel,
                      style: TextStyle(
                        color: onSurface.withAlpha(140),
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 当天训练卡片
                  ...exercises.map((e) => _ExerciseStoryCard(exercise: e)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseStoryCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseStoryCard({required this.exercise});

  String _fmtDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final typeColor = _typeColor(exercise);

    IconData icon;
    if (exercise.isStrength) {
      icon = Icons.fitness_center;
    } else if (exercise.typeName == '跑步') {
      icon = Icons.directions_run;
    } else if (exercise.typeName == '骑行') {
      icon = Icons.directions_bike;
    } else {
      icon = Icons.sports;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: typeColor, width: 3),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: typeColor.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: typeColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.displayName,
                    style: TextStyle(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 副信息行
                  _buildSubInfo(context, onSurface),
                ],
              ),
            ),
            // 右侧时长
            if (exercise.durationSeconds > 0)
              Text(
                _fmtDuration(exercise.durationSeconds),
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubInfo(BuildContext context, Color onSurface) {
    final parts = <String>[];
    if (exercise.isStrength) {
      if (exercise.completedSets > 0) parts.add('${exercise.completedSets}组');
      if (exercise.reps != null) parts.add('${exercise.reps}次/组');
    } else {
      if (exercise.distance != null && exercise.distance! > 0) {
        parts.add('${exercise.distance!.toStringAsFixed(1)}km');
      }
    }
    if (parts.isEmpty) {
      parts.add(exercise.typeName);
    }
    return Text(
      parts.join('  ·  '),
      style: TextStyle(color: onSurface.withAlpha(120), fontSize: 11),
    );
  }
}

// ── 通用：章节标题 ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
