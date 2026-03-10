import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_card.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_placeholder.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/screens/ai_review_history_modal.dart';

enum _AiReviewState { loading, hasReview, empty, running }

class ProjectDetailsView extends StatefulWidget {
  final Project? project;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final ProjectService? projectService;
  final TaskService? taskService;
  final AiReviewService? aiReviewService;
  final Future<void> Function(Project updatedProject)? onProjectUpdated;

  const ProjectDetailsView({
    super.key,
    this.project,
    this.onClose,
    this.onDelete,
    this.projectService,
    this.taskService,
    this.aiReviewService,
    this.onProjectUpdated,
  });

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  late final ProjectService _projectService;
  late final TaskService _taskService;
  late final AiReviewService _aiReviewService;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorId = 0;
  String _selectedStatus = 'ACTIVE';
  Timer? _debounceTimer;
  bool _isSaving = false;
  List<int> _activityData = List.filled(30, 0);
  int _activeTaskCount = 0;
  int _doneTaskCount = 0;
  _AiReviewState _aiState = _AiReviewState.loading;
  AIReviewRead? _currentReview;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? getIt<ProjectService>();
    _taskService = widget.taskService ?? getIt<TaskService>();
    _aiReviewService = widget.aiReviewService ?? getIt<AiReviewService>();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _getProjectDetails();
    _loadActivityData();
    _loadReview();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project?.id != oldWidget.project?.id) {
      _updateData();
      _loadActivityData();
      _stopPolling();
      _loadReview();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getProjectDetails() async {
    if (widget.project == null) return;
    if (mounted) {
      setState(() {
        _nameController.text = widget.project!.name;
        _descriptionController.text = widget.project!.description ?? '';
        _selectedColorId = int.tryParse(widget.project!.colorId ?? '0') ?? 0;
        _selectedStatus = widget.project!.status;
      });
    }
  }

  Future<void> _loadActivityData() async {
    if (widget.project == null) return;
    try {
      final tasks = await _taskService.getTasksByProject(projectId: widget.project!.id);
      if (mounted) {
        setState(() {
          _activityData = _computeActivityData(tasks);
          _activeTaskCount = tasks.where((t) => t.status != 'DONE').length;
          _doneTaskCount = tasks.where((t) => t.status == 'DONE').length;
        });
      }
    } catch (_) {}
  }

  List<int> _computeActivityData(List<Task> tasks) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final counts = List<int>.filled(30, 0);
    for (final task in tasks) {
      if (task.closedAt == null) continue;
      final closed = DateTime(task.closedAt!.year, task.closedAt!.month, task.closedAt!.day);
      final diff = todayDate.difference(closed).inDays;
      if (diff >= 0 && diff < 30) counts[29 - diff]++;
    }
    return counts;
  }

  // ─── AI Review ────────────────────────────────────────────────────────────

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadReview() async {
    if (!mounted) return;
    setState(() {
      _aiState = _AiReviewState.loading;
      _currentReview = null;
    });
    if (widget.project == null) return;
    final review = await _aiReviewService.getActiveProjectReview(widget.project!.id);
    if (!mounted) return;
    setState(() {
      _currentReview = review;
      _aiState = review != null ? _AiReviewState.hasReview : _AiReviewState.empty;
    });
  }

  Future<void> _startReview() async {
    if (!mounted || widget.project == null) return;
    setState(() => _aiState = _AiReviewState.running);
    try {
      final celeryId = await _aiReviewService.runProjectReview(widget.project!.id);
      _startPolling(celeryId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось запустить ревью, попробуй ещё раз')),
      );
      setState(() => _aiState = _currentReview != null
          ? _AiReviewState.hasReview
          : _AiReviewState.empty);
    }
  }

  void _startPolling(String celeryId) {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final status = await _aiReviewService.getReviewStatus(celeryId);
      if (!mounted) { _stopPolling(); return; }
      if (status == 'done') {
        _stopPolling();
        await _loadReview();
      } else if (status == 'error') {
        _stopPolling();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось получить ревью, попробуй ещё раз')),
          );
          setState(() => _aiState = _currentReview != null
              ? _AiReviewState.hasReview
              : _AiReviewState.empty);
        }
      }
    });
  }

  void _openHistory() {
    if (widget.project == null) return;
    showDialog(
      context: context,
      builder: (_) => AiReviewHistoryModal(projectId: widget.project!.id),
    );
  }

  void _updateData() {
    if (widget.project == null) return;
    if (_nameController.text != widget.project!.name) {
      _nameController.text = widget.project!.name;
    }
    final newDesc = widget.project!.description ?? '';
    if (_descriptionController.text != newDesc) {
      _descriptionController.text = newDesc;
    }
    final newColorId = int.tryParse(widget.project!.colorId ?? '0') ?? 0;
    if (_selectedColorId != newColorId) setState(() => _selectedColorId = newColorId);
    if (_selectedStatus != widget.project!.status) {
      setState(() => _selectedStatus = widget.project!.status);
    }
  }

  Future<void> _performUpdate(Project updated) async {
    if (widget.onProjectUpdated == null) return;
    setState(() => _isSaving = true);
    try {
      await Future.wait([
        widget.onProjectUpdated!(updated),
        Future.delayed(const Duration(milliseconds: 800)),
      ]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2000), _saveChanges);
  }

  void _saveChanges() {
    if (widget.project == null) return;
    _performUpdate(widget.project!.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    ));
  }

  void _changeColor(int newColorId) {
    if (widget.project == null) return;
    setState(() => _selectedColorId = newColorId);
    _performUpdate(widget.project!.copyWith(colorId: newColorId.toString()));
  }

  void _changeStatus(String newStatus) {
    if (widget.project == null) return;
    setState(() => _selectedStatus = newStatus);
    _performUpdate(widget.project!.copyWith(status: newStatus));
  }

  Future<void> _changeDeadline() async {
    if (widget.project == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.project!.deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final newDate = DateTime(picked.year, picked.month, picked.day, 12, 0);
      _performUpdate(widget.project!.copyWith(deadline: newDate));
    }
  }

  Future<void> _deleteProject() async {
    if (widget.project == null) return;
    try {
      await _projectService.deleteProject(projectId: widget.project!.id);
      if (mounted) widget.onDelete?.call();
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        });
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── Шапка ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final colorIndex = _selectedColorId;
    final dotColor = ProjectColorData.getColor(context, colorIndex);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Цветная точка + название + кнопка закрытия
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showColorPicker(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => _onFieldChanged(),
                  style: AppTextStyles.inspectorTitle,
                  decoration: const InputDecoration(
                    hintText: 'Название проекта',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 1,
                ),
              ),
              if (widget.onClose != null)
                GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_activeTaskCount активных · $_doneTaskCount выполнено',
            style: AppTextStyles.metaText,
          ),
          const SizedBox(height: 8),
          // Спарклайн активности
          _ActivitySparkline(data: _activityData),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Цвет проекта'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            ProjectColorData.palette.length,
            (i) => GestureDetector(
              onTap: () {
                _changeColor(i);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ProjectColorData.getColor(context, i),
                  shape: BoxShape.circle,
                  border: i == _selectedColorId
                      ? Border.all(color: AppColors.textPrimary, width: 2)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Тело ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Секция: Детали ──
          _SectionLabel(label: 'Детали'),
          const SizedBox(height: 6),

          _FieldRow(
            label: 'Статус',
            child: _StatusDropdown(
              value: _selectedStatus,
              onChanged: _changeStatus,
            ),
          ),

          _FieldRow(
            label: 'Дедлайн',
            child: GestureDetector(
              onTap: _changeDeadline,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  widget.project?.deadline != null
                      ? dateFormat.format(widget.project!.deadline!)
                      : 'Не задан',
                  style: AppTextStyles.bodyText.copyWith(
                    color: widget.project?.deadline != null
                        ? (widget.project!.deadline!.isBefore(DateTime.now())
                            ? AppColors.tomato
                            : AppColors.textPrimary)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),

          if (widget.project?.updatedAt != null)
            _FieldRow(
              label: 'Обновлено',
              child: Text(
                DateFormat('dd MMM yyyy, HH:mm').format(widget.project!.updatedAt!),
                style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
              ),
            ),

          const SizedBox(height: 18),

          // ── Секция: Описание ──
          _SectionLabel(label: 'Описание'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _descriptionController,
              onChanged: (_) => _onFieldChanged(),
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Добавьте описание...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),
          ),

          const SizedBox(height: 18),

          // ── Секция: AI Ментор ──
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _SectionLabel(label: 'AI Ментор')),
              if (_aiState == _AiReviewState.hasReview)
                _AiButton(label: 'Обновить', onPressed: _startReview),
            ],
          ),
          const SizedBox(height: 8),
          _buildAiSection(),

        ],
      ),
    );
  }

  Widget _buildAiSection() {
    switch (_aiState) {
      case _AiReviewState.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      case _AiReviewState.running:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Ментор анализирует проект...',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        );
      case _AiReviewState.empty:
        return AiReviewPlaceholder(
          buttonLabel: 'Проверить проект',
          onPressed: _startReview,
        );
      case _AiReviewState.hasReview:
        final r = _currentReview!;
        final dateStr = DateFormat('d MMM, HH:mm').format(r.createdAt.toLocal());
        return AiReviewCard(
          verdict: r.comment.verdict,
          score: r.comment.score,
          issues: r.comment.questions,
          suggestion: r.comment.questions.isNotEmpty ? r.comment.questions.last : '',
          date: dateStr,
          onTap: _openHistory,
          onHistoryTap: _openHistory,
        );
    }
  }

  // ─── Футер ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    if (!_isSaving && widget.onDelete == null) return const SizedBox(height: 1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onDelete != null)
            GestureDetector(
              onTap: _deleteProject,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 15, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Удалить проект',
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.accent),
                    ),
                  ]),
                ),
              ),
            ),
          if (_isSaving)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Сохранение...', style: AppTextStyles.metaText),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Спарклайн активности ─────────────────────────────────────────────────────

class _ActivitySparkline extends StatelessWidget {
  final List<int> data;
  const _ActivitySparkline({required this.data});

  @override
  Widget build(BuildContext context) {
    assert(data.length == 30);
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final value = data[i];
          final isToday = i == data.length - 1;
          final heightFraction = maxVal > 0 ? value / maxVal : 0.0;
          final barHeight = (heightFraction * 20).clamp(2.0, 20.0).toDouble();
          final opacity = isToday
              ? 1.0
              : value > 0
                  ? 0.65
                  : 0.25;

          return Tooltip(
            message: _tooltipText(i, value),
            preferBelow: false,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(5),
            ),
            textStyle: const TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(
                width: 5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: opacity),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _tooltipText(int index, int value) {
    final date = DateTime.now().subtract(Duration(days: 29 - index));
    final dateStr = '${date.day} ${_monthShort(date.month)}';
    return '$dateStr · $value';
  }

  static String _monthShort(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return months[month - 1];
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTextStyles.sectionLabel);
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const _AiButton({required this.label, this.onPressed});

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF5D5D0) : AppColors.accentLight,
            border: Border.all(color: const Color(0xFFE8B5B0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.accent,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
        items: const [
          DropdownMenuItem(value: 'ACTIVE', child: Text('Активен')),
          DropdownMenuItem(value: 'COMPLETED', child: Text('Завершён')),
          DropdownMenuItem(value: 'CANCELED', child: Text('Отменён')),
        ],
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
