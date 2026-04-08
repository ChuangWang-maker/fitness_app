import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  firstDate ??= DateTime(2020);
  lastDate ??= DateTime.now().add(const Duration(days: 365));

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => _WheelDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate!,
      lastDate: lastDate!,
    ),
  );
}

class _WheelDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _WheelDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_WheelDatePickerDialog> createState() => _WheelDatePickerDialogState();
}

class _WheelDatePickerDialogState extends State<_WheelDatePickerDialog> {
  late int _year, _month, _day;
  late DateTime _selected;
  late List<int> _years;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _year = _selected.year;
    _month = _selected.month;
    _day = _selected.day;

    _years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );

    _yearCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_year));
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  void _onWheelChanged(int year, int month) {
    final maxDay = DateTime(year, month + 1, 0).day;
    final safeDay = _day.clamp(1, maxDay);
    setState(() {
      _year = year;
      _month = month;
      _day = safeDay;
      _selected = DateTime(_year, _month, _day);
    });
  }

  void _onCalendarTap(int day) {
    setState(() {
      _day = day;
      _selected = DateTime(_year, _month, _day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bgColor = Theme.of(context).colorScheme.surface;
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '选择日期',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_year}年${_month}月${_day}日',
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // 内容区：左滚轮 + 右日历
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左：年/月两列滚轮
                  SizedBox(
                    width: 110,
                    child: Stack(
                      children: [
                        // 选中高亮条
                        Center(
                          child: Container(
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // 年
                            Expanded(
                              flex: 6,
                              child: CupertinoPicker(
                                scrollController: _yearCtrl,
                                itemExtent: 36,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (i) {
                                    Vibration.vibrate(duration: 20);
                                    _onWheelChanged(_years[i], _month);
                                  },
                                children: _years.map((y) => Center(
                                  child: Text(
                                    '$y',
                                    style: TextStyle(
                                      color: y == _year
                                          ? primary
                                          : onSurface.withAlpha(140),
                                      fontSize: y == _year ? 14 : 12,
                                      fontWeight: y == _year
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            // 月
                            Expanded(
                              flex: 4,
                              child: CupertinoPicker(
                                scrollController: _monthCtrl,
                                itemExtent: 36,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (i) {
                                    Vibration.vibrate(duration: 20);
                                    _onWheelChanged(_year, i + 1);
                                  },
                                children: List.generate(12, (i) => Center(
                                  child: Text(
                                    '${i + 1}月',
                                    style: TextStyle(
                                      color: i + 1 == _month
                                          ? primary
                                          : onSurface.withAlpha(140),
                                      fontSize: i + 1 == _month ? 14 : 12,
                                      fontWeight: i + 1 == _month
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 分割线
                  VerticalDivider(width: 1, color: onSurface.withAlpha(25)),

                  // 右：日历网格
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                      child: _CalendarGrid(
                        year: _year,
                        month: _month,
                        selectedDay: _day,
                        today: now,
                        onTap: _onCalendarTap,
                        primary: primary,
                        onSurface: onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 底部按钮
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消',
                          style: TextStyle(
                              color: onSurface.withAlpha(150), fontSize: 15)),
                    ),
                  ),
                  VerticalDivider(
                      width: 1, color: onSurface.withAlpha(25), indent: 8, endIndent: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text('确定',
                          style: TextStyle(
                              color: primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final int selectedDay;
  final DateTime today;
  final ValueChanged<int> onTap;
  final Color primary;
  final Color onSurface;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.onTap,
    required this.primary,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Column(
      children: [
        // 星期标题
        Row(
          children: ['日', '一', '二', '三', '四', '五', '六'].map((d) => Expanded(
            child: Center(
              child: Text(d,
                  style: TextStyle(
                      color: onSurface.withAlpha(90), fontSize: 9)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 2),

        // 日期格
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final isSelected = day == selectedDay;
              final isToday = year == today.year &&
                  month == today.month &&
                  day == today.day;

              return GestureDetector(
                onTap: () => onTap(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : isToday
                            ? primary.withAlpha(35)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? primary
                                : onSurface,
                        fontSize: 10,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
