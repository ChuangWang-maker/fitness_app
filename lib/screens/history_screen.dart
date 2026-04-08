import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/workout_provider.dart';
import '../models/exercise.dart';
import '../services/database_service.dart';
import '../widgets/exercise_card.dart';
import '../app.dart';
import 'workout_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    // 监听 WorkoutProvider，训练增删后日历自动刷新
    context.watch<WorkoutProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: const ThemeToggleButton(),
        title: const Text('训练历史'),
      ),
      body: Column(
        children: [
          _buildCalendar(context),
          const Divider(height: 1),
          Expanded(child: _buildDayExercises(context)),
        ],
      ),
    );
  }

  // ── 简易月历 ────────────────────────────────────────────────
  Widget _buildCalendar(BuildContext context) {
    final recordedDates = DatabaseService.getAllRecordedDates();
    final plannedDates = DatabaseService.getAllPlannedDates();
    final now = DateTime.now();
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=日,1=一,...

    return Column(
      children: [
        // 月份导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
              ),
              Text(
                DateFormat('yyyy年 M月').format(_focusedMonth),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
              ),
            ],
          ),
        ),
        // 星期标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // 日期格
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final dateKey =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final hasRecord = recordedDates.contains(dateKey);
              final hasPlanned = plannedDates.contains(dateKey);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day;
              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isFuture = date.isAfter(now);

              return _DayCell(
                day: day,
                hasRecord: hasRecord,
                hasPlanned: hasPlanned,
                isSelected: isSelected,
                isToday: isToday,
                isFuture: isFuture,
                onTap: () => setState(() {
                  _selectedDay = isSelected ? null : date;
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 当天训练列表 ────────────────────────────────────────────
  Widget _buildDayExercises(BuildContext context) {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          '选择日期查看训练记录',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
        ),
      );
    }

    final exercises = DatabaseService.getExercisesByDate(_selectedDay!);
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          '${DateFormat('M月d日').format(_selectedDay!)} 没有训练记录',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final isPast = sel.isBefore(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DateFormat('M月d日 训练记录').format(_selectedDay!),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...exercises.map(
          (e) => ExerciseCard(
            exercise: e,
            readOnly: isPast,
            onTap: () {
              if (isPast || e.status == ExerciseStatus.completed) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(exercise: e),
                ),
              );
            },
            onDelete: isPast
                ? null
                : () => context.read<WorkoutProvider>().deleteExercise(e.id),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasRecord;
  final bool hasPlanned;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.hasRecord,
    required this.hasPlanned,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Color bgColor = Colors.transparent;
    Color textColor = onSurface;
    FontWeight fontWeight = FontWeight.normal;

    if (isSelected) {
      bgColor = isFuture ? secondary : primary;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
    } else if (isToday) {
      bgColor = primary.withAlpha(40);
      textColor = primary;
      fontWeight = FontWeight.bold;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          // 过去有记录：橙色圆点
          if (hasRecord && !isSelected)
            Positioned(
              bottom: 3,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              ),
            ),
          // 未来有计划：蓝色圆点
          if (hasPlanned && !hasRecord && !isSelected)
            Positioned(
              bottom: 3,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: secondary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
