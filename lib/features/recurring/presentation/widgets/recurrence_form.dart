import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';

class RecurrenceForm extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String? taskProjectId;
  final RecurringTask? existing;
  final RecurringTaskService recurringTaskService;
  final void Function(RecurringTask saved) onSaved;

  const RecurrenceForm({
    super.key,
    required this.taskId,
    required this.taskName,
    this.taskProjectId,
    this.existing,
    required this.recurringTaskService,
    required this.onSaved,
  });

  @override
  State<RecurrenceForm> createState() => _RecurrenceFormState();
}

class _RecurrenceFormState extends State<RecurrenceForm> {
  late RecurringFrequency _frequency;
  late Set<int> _selectedDays;
  final TextEditingController _intervalController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  static const _weekDayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _frequency = e.frequency;
      _selectedDays = Set.from(e.days);
      if (e.frequency == RecurringFrequency.interval) {
        _intervalController.text =
            e.days.isNotEmpty ? e.days.first.toString() : '1';
      }
    } else {
      _frequency = RecurringFrequency.daily;
      _selectedDays = {};
      _intervalController.text = '1';
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  bool _validate() {
    switch (_frequency) {
      case RecurringFrequency.daily:
        return true;
      case RecurringFrequency.weekly:
        if (_selectedDays.isEmpty) {
          setState(() => _error = 'Выберите хотя бы один день');
          return false;
        }
        return true;
      case RecurringFrequency.monthly:
        if (_selectedDays.isEmpty) {
          setState(() => _error = 'Выберите хотя бы одно число');
          return false;
        }
        return true;
      case RecurringFrequency.interval:
        final n = int.tryParse(_intervalController.text.trim());
        if (n == null || n < 1) {
          setState(() => _error = 'Введите число от 1 и выше');
          return false;
        }
        return true;
    }
  }

  List<int> _buildDays() {
    switch (_frequency) {
      case RecurringFrequency.daily:
        return [];
      case RecurringFrequency.weekly:
        return _selectedDays.toList()..sort();
      case RecurringFrequency.monthly:
        return _selectedDays.toList()..sort();
      case RecurringFrequency.interval:
        return [int.parse(_intervalController.text.trim())];
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_validate()) return;

    setState(() => _isSaving = true);
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final data = {
        'frequency': _frequency.name,
        'days': _buildDays(),
        'timezone': timezone,
      };

      RecurringTask saved;
      if (widget.existing != null) {
        saved = await widget.recurringTaskService.update(widget.existing!.id, data);
      } else {
        saved = await widget.recurringTaskService.create({
          ...data,
          'task_id': int.tryParse(widget.taskId) ?? widget.taskId,
          'name': widget.taskName,
          if (widget.taskProjectId != null)
            'project_id': int.tryParse(widget.taskProjectId!) ?? widget.taskProjectId,
        });
      }

      if (mounted) {
        widget.onSaved(saved);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Не удалось сохранить расписание';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Повторение',
            style: AppTextStyles.modalTitle,
          ),
          const SizedBox(height: 20),
          _buildFrequencySelector(),
          const SizedBox(height: 16),
          _buildDaysInput(),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.metaText.copyWith(color: AppColors.accent),
            ),
          ],
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final options = [
      (RecurringFrequency.daily, 'Каждый день'),
      (RecurringFrequency.weekly, 'По дням недели'),
      (RecurringFrequency.monthly, 'По числам'),
      (RecurringFrequency.interval, 'Интервал'),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final isSelected = _frequency == opt.$1;
        return GestureDetector(
          onTap: () => setState(() {
            _frequency = opt.$1;
            _selectedDays = {};
            _error = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.bgActive : AppColors.bgHover,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.border : Colors.transparent,
              ),
            ),
            child: Text(
              opt.$2,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysInput() {
    switch (_frequency) {
      case RecurringFrequency.daily:
        return const SizedBox.shrink();
      case RecurringFrequency.weekly:
        return _buildWeekDays();
      case RecurringFrequency.monthly:
        return _buildMonthDays();
      case RecurringFrequency.interval:
        return _buildInterval();
    }
  }

  Widget _buildWeekDays() {
    return Wrap(
      spacing: 6,
      children: List.generate(7, (i) {
        final selected = _selectedDays.contains(i);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedDays.remove(i);
            } else {
              _selectedDays.add(i);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.bgHover,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _weekDayNames[i],
              style: AppTextStyles.metaText.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthDays() {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(31, (i) {
        final day = i + 1;
        final selected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedDays.remove(day);
            } else {
              _selectedDays.add(day);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.bgHover,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: AppTextStyles.metaText.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInterval() {
    return Row(
      children: [
        Text(
          'Каждые',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'дней',
          style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isSaving ? AppColors.bgActive : AppColors.accent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Сохранить',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
