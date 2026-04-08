import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/exercise_type.dart';
import '../models/exercise_action.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_card.dart';
import 'workout_screen.dart';
import 'manage_actions_screen.dart';
import '../widgets/wheel_date_picker.dart';

class AddExerciseScreen extends StatefulWidget {
  final DateTime initialDate;
  final Exercise? editingExercise; // 非 null 时为编辑模式

  const AddExerciseScreen({
    super.key,
    required this.initialDate,
    this.editingExercise,
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  late DateTime _selectedDate;
  ExerciseType? _selectedType;
  ExerciseAction? _selectedAction;

  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '12');
  final _restCtrl = TextEditingController(text: '60');
  final _distanceCtrl = TextEditingController();

  TimeOfDay? _scheduledTime;

  bool get _isEditing => widget.editingExercise != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    final ex = widget.editingExercise;
    if (ex != null) {
      // 编辑模式：预填数据
      final provider = context.read<WorkoutProvider>();
      _selectedType = provider.exerciseTypes.firstWhere(
        (t) => t.id == ex.typeId,
        orElse: () => provider.exerciseTypes.first,
      );
      if (ex.actionId != null) {
        try {
          _selectedAction = provider.exerciseActions
              .firstWhere((a) => a.id == ex.actionId);
        } catch (_) {}
      }
      if (ex.sets != null) _setsCtrl.text = ex.sets.toString();
      if (ex.reps != null) _repsCtrl.text = ex.reps.toString();
      if (ex.restSeconds != null) _restCtrl.text = ex.restSeconds.toString();
      if (ex.distance != null) _distanceCtrl.text = ex.distance.toString();
      if (ex.scheduledTime != null) {
        _scheduledTime = TimeOfDay(
          hour: ex.scheduledTime!.hour,
          minute: ex.scheduledTime!.minute,
        );
      }
    }
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _restCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get _isFuture {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return sel.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final dayExercises = provider.getExercisesByDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑训练' : '添加训练'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                // ── 日期选择 ─────────────────────────────────
                _buildDateSelector(context),
                const SizedBox(height: 20),

                // ── 训练类型 ─────────────────────────────────
                _buildSectionTitle('训练类型'),
                const SizedBox(height: 10),
                _buildTypeGrid(provider.exerciseTypes),

                // ── 力量：动作选择 ────────────────────────────
                if (_selectedType?.isStrength == true) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('选择动作'),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageActionsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 14),
                        label: const Text('管理动作', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildActionGrid(provider.exerciseActions),
                ],

                // ── 参数 ─────────────────────────────────────
                if (_selectedType != null) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('训练参数'),
                  const SizedBox(height: 10),
                  _selectedType!.isStrength
                      ? _buildStrengthParams()
                      : _buildCardioParams(),
                  const SizedBox(height: 16),
                  _buildTimeSelector(context),
                  const SizedBox(height: 24),
                  _buildActionButton(context, provider),
                ],

                // ── 当天其他训练 ──────────────────────────────
                if (dayExercises.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    '${DateFormat('M月d日').format(_selectedDate)}的其他训练',
                  ),
                  const SizedBox(height: 10),
                  ...dayExercises
                      .where((e) => e.id != widget.editingExercise?.id)
                      .map(
                        (e) => ExerciseCard(
                          exercise: e,
                          readOnly: true,
                          onTap: () {},
                        ),
                      ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 日期选择器 ────────────────────────────────────────────
  Widget _buildDateSelector(BuildContext context) {
    final label = _isToday
        ? '今天'
        : _isFuture
            ? '计划日期'
            : '历史日期';
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onSurface.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: onSurface.withAlpha(150), fontSize: 11),
                ),
                Text(
                  DateFormat('yyyy年M月d日 (E)', 'zh_CN').format(_selectedDate),
                  style: TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showWheelDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── 训练类型格 ────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (context) => Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeGrid(List<ExerciseType> types) {
    // 内置类型在前，自定义类型在后，顺序稳定
    final sorted = [...types]..sort((a, b) {
        if (a.isCustom == b.isCustom) return 0;
        return a.isCustom ? 1 : -1;
      });
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...sorted.map((type) {
          final isSelected = _selectedType?.id == type.id;
          final chip = _SelectChip(
            label: type.name,
            icon: type.isStrength ? Icons.fitness_center : Icons.directions_run,
            isSelected: isSelected,
            onTap: () => setState(() {
              _selectedType = type;
              _selectedAction = null;
            }),
          );
          if (!type.isCustom) return chip;
          // 自定义类型：加红色删除角标
          return Stack(
            clipBehavior: Clip.none,
            children: [
              chip,
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除训练类型'),
                        content: Text('确定要删除「${type.name}」吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('删除',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    if (_selectedType?.id == type.id) {
                      setState(() {
                        _selectedType = null;
                        _selectedAction = null;
                      });
                    }
                    await context.read<WorkoutProvider>().deleteCustomType(type.id);
                  },
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        _AddTypeChip(
          onAdd: (name, category) =>
              context.read<WorkoutProvider>().addCustomType(name, category),
        ),
      ],
    );
  }

  // ── 动作格（力量专用） ────────────────────────────────────
  Widget _buildActionGrid(List<ExerciseAction> actions) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((action) {
        final isSelected = _selectedAction?.id == action.id;
        return _SelectChip(
          label: action.name,
          icon: Icons.sports_gymnastics,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedAction = isSelected ? null : action),
        );
      }).toList(),
    );
  }

  // ── 参数输入 ─────────────────────────────────────────────
  Widget _buildStrengthParams() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _NumberField(label: '组数', controller: _setsCtrl, suffix: '组')),
            const SizedBox(width: 12),
            Expanded(child: _NumberField(label: '每组次数', controller: _repsCtrl, suffix: '次')),
          ],
        ),
        const SizedBox(height: 12),
        _NumberField(label: '组间休息', controller: _restCtrl, suffix: '秒'),
      ],
    );
  }

  Widget _buildCardioParams() {
    return _NumberField(
      label: '计划距离（可选）',
      controller: _distanceCtrl,
      suffix: 'km',
      isDecimal: true,
    );
  }

  // ── 时间选择 ─────────────────────────────────────────────
  Widget _buildTimeSelector(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () => _pickTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onSurface.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('计划时间（可选）',
                    style: TextStyle(color: onSurface.withAlpha(150), fontSize: 11)),
                Text(
                  _scheduledTime != null
                      ? _scheduledTime!.format(context)
                      : '未设置',
                  style: TextStyle(color: onSurface, fontSize: 15),
                ),
              ],
            ),
            const Spacer(),
            if (_scheduledTime != null)
              GestureDetector(
                onTap: () => setState(() => _scheduledTime = null),
                child: Icon(Icons.close, color: onSurface.withAlpha(100), size: 18),
              )
            else
              Icon(Icons.chevron_right, color: onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  // ── 操作按钮 ─────────────────────────────────────────────
  Widget _buildActionButton(BuildContext context, WorkoutProvider provider) {
    if (_isEditing) {
      return ElevatedButton.icon(
        onPressed: () => _saveEdit(context, provider),
        icon: const Icon(Icons.save_outlined),
        label: const Text('保存修改'),
      );
    }

    // 今天：并排显示「添加计划」和「开始训练」；未来：只显示「添加计划」
    if (_isToday) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _addPlan(context, provider),
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('添加计划', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _startWorkout(context, provider),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('直接开始训练'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _addPlan(context, provider),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('添加计划', style: TextStyle(fontSize: 16)),
      );
    }
  }

  // ── 提交逻辑 ─────────────────────────────────────────────
  DateTime? _buildScheduledDateTime() {
    if (_scheduledTime == null) return null;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );
  }

  Future<void> _startWorkout(BuildContext context, WorkoutProvider provider) async {
    if (_selectedType == null) return;
    final exercise = await provider.addExercise(
      type: _selectedType!,
      date: _selectedDate,
      sets: _selectedType!.isStrength ? int.tryParse(_setsCtrl.text) : null,
      reps: _selectedType!.isStrength ? int.tryParse(_repsCtrl.text) : null,
      restSeconds: _selectedType!.isStrength ? int.tryParse(_restCtrl.text) : null,
      distance: _selectedType!.isCardio ? double.tryParse(_distanceCtrl.text) : null,
      actionId: _selectedAction?.id,
      actionName: _selectedAction?.name,
      scheduledTime: _buildScheduledDateTime(),
    );
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutScreen(exercise: exercise)));
  }

  Future<void> _addPlan(BuildContext context, WorkoutProvider provider) async {
    if (_selectedType == null) return;
    await provider.addExercise(
      type: _selectedType!,
      date: _selectedDate,
      sets: _selectedType!.isStrength ? int.tryParse(_setsCtrl.text) : null,
      reps: _selectedType!.isStrength ? int.tryParse(_repsCtrl.text) : null,
      restSeconds: _selectedType!.isStrength ? int.tryParse(_restCtrl.text) : null,
      distance: _selectedType!.isCardio ? double.tryParse(_distanceCtrl.text) : null,
      actionId: _selectedAction?.id,
      actionName: _selectedAction?.name,
      scheduledTime: _buildScheduledDateTime(),
    );
    if (!context.mounted) return;
    provider.selectDate(_selectedDate);
    // 留在当前页，重置选择状态，底部列表会自动刷新
    setState(() {
      _selectedType = null;
      _selectedAction = null;
      _scheduledTime = null;
      _distanceCtrl.clear();
      _setsCtrl.text = '3';
      _repsCtrl.text = '12';
      _restCtrl.text = '60';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('计划已添加'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveEdit(BuildContext context, WorkoutProvider provider) async {
    final ex = widget.editingExercise!;
    await provider.editExercise(
      exercise: ex,
      sets: _selectedType?.isStrength == true ? int.tryParse(_setsCtrl.text) : null,
      reps: _selectedType?.isStrength == true ? int.tryParse(_repsCtrl.text) : null,
      restSeconds: _selectedType?.isStrength == true ? int.tryParse(_restCtrl.text) : null,
      distance: _selectedType?.isCardio == true ? double.tryParse(_distanceCtrl.text) : null,
      actionId: _selectedAction?.id,
      actionName: _selectedAction?.name,
      scheduledTime: _buildScheduledDateTime(),
    );
    if (!context.mounted) return;
    Navigator.pop(context);
  }
}

// ── 通用选择芯片 ─────────────────────────────────────────────
class _SelectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withAlpha(40) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : onSurface.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primary : onSurface.withAlpha(150), size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primary : onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 数字输入框 ────────────────────────────────────────────────
class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final bool isDecimal;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.suffix,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        isDecimal
            ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}

// ── 添加自定义类型芯片 ──────────────────────────────────────────
class _AddTypeChip extends StatelessWidget {
  final Future<void> Function(String name, ExerciseCategory category) onAdd;

  const _AddTypeChip({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () => _showAddDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onSurface.withAlpha(60),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: onSurface.withAlpha(150), size: 16),
            const SizedBox(width: 5),
            Text(
              '自定义',
              style: TextStyle(color: onSurface.withAlpha(150), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddTypeDialog(onAdd: onAdd),
    );
  }
}

class _AddTypeDialog extends StatefulWidget {
  final Future<void> Function(String name, ExerciseCategory category) onAdd;

  const _AddTypeDialog({required this.onAdd});

  @override
  State<_AddTypeDialog> createState() => _AddTypeDialogState();
}

class _AddTypeDialogState extends State<_AddTypeDialog> {
  final _nameCtrl = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.cardio;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加训练类型'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '类型名称',
              hintText: '例如：游泳、跳绳',
            ),
          ),
          const SizedBox(height: 16),
          const Text('类别', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _CategoryOption(
                label: '有氧',
                icon: Icons.directions_run,
                selected: _category == ExerciseCategory.cardio,
                onTap: () => setState(() => _category = ExerciseCategory.cardio),
              ),
              const SizedBox(width: 10),
              _CategoryOption(
                label: '力量',
                icon: Icons.fitness_center,
                selected: _category == ExerciseCategory.strength,
                onTap: () => setState(() => _category = ExerciseCategory.strength),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            await widget.onAdd(name, _category);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? primary : onSurface.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? primary : onSurface.withAlpha(150)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? primary : onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
