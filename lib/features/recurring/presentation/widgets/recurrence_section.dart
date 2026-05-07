import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';
import 'package:kabachok_lasalsa_front/features/recurring/presentation/widgets/recurrence_form.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';

enum _RecurrenceState { loading, empty, loaded }

class RecurrenceSection extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String? taskProjectId;
  final RecurringTaskService? recurringTaskService;

  const RecurrenceSection({
    super.key,
    required this.taskId,
    required this.taskName,
    this.taskProjectId,
    this.recurringTaskService,
  });

  @override
  State<RecurrenceSection> createState() => _RecurrenceSectionState();
}

class _RecurrenceSectionState extends State<RecurrenceSection> {
  late final RecurringTaskService _service;
  _RecurrenceState _state = _RecurrenceState.loading;
  RecurringTask? _recurring;

  @override
  void initState() {
    super.initState();
    _service = widget.recurringTaskService ?? getIt<RecurringTaskService>();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecurrenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taskId != oldWidget.taskId) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _state = _RecurrenceState.loading);
    final result = await _service.getByTaskId(widget.taskId);
    if (!mounted) return;
    setState(() {
      _recurring = result;
      _state = result != null ? _RecurrenceState.loaded : _RecurrenceState.empty;
    });
  }

  Future<void> _openForm({RecurringTask? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecurrenceForm(
        taskId: widget.taskId,
        taskName: widget.taskName,
        taskProjectId: widget.taskProjectId,
        existing: existing,
        recurringTaskService: _service,
        onSaved: (saved) {
          if (mounted) {
            setState(() {
              _recurring = saved;
              _state = _RecurrenceState.loaded;
            });
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить повторение?'),
        content: const Text('Задача останется, повторение будет отключено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.delete(_recurring!.id);
      if (mounted) {
        setState(() {
          _recurring = null;
          _state = _RecurrenceState.empty;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить расписание')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _RecurrenceState.loading => _buildLoading(),
      _RecurrenceState.empty => _buildEmpty(),
      _RecurrenceState.loaded => _buildLoaded(_recurring!),
    };
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Повторение'),
        const SizedBox(height: 8),
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SectionLabel(label: 'Повторение'),
        _SmallAiButton(
          label: '+ Добавить',
          onPressed: _openForm,
        ),
      ],
    );
  }

  Widget _buildLoaded(RecurringTask r) {
    final nextStr = _formatNextRun(r.nextRunAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel(label: 'Повторение'),
            _SmallAiButton(
              label: 'Изменить',
              onPressed: () => _openForm(existing: r),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.repeat, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              formatRecurrence(r),
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Следующий: $nextStr',
          style: AppTextStyles.metaText.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _confirmDelete,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              'Удалить',
              style: AppTextStyles.metaText.copyWith(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNextRun(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('EEE, d MMM').format(local);
  }
}

// ─── Вспомогательные виджеты ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.sectionLabel,
    );
  }
}

class _SmallAiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const _SmallAiButton({required this.label, this.onPressed});

  @override
  State<_SmallAiButton> createState() => _SmallAiButtonState();
}

class _SmallAiButtonState extends State<_SmallAiButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF5D5D0) : AppColors.accentLight,
            border: Border.all(color: const Color(0xFFE8B5B0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.accent,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
