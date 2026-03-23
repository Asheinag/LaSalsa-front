import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_card.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_placeholder.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/screens/ai_review_history_modal.dart';

enum _AiReviewState { loading, hasReview, empty, running }

class TaskDetailView extends StatefulWidget {
  final Task? task;
  final List<Project> projects;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final Future<void> Function(Task updatedTask)? onTaskUpdated;
  final TaskService? taskService;
  final AiReviewService? aiReviewService;
  final bool showAiReview;

  const TaskDetailView({
    super.key,
    this.task,
    this.projects = const [],
    this.onClose,
    this.onDelete,
    this.onTaskUpdated,
    this.taskService,
    this.aiReviewService,
    this.showAiReview = true,
  });

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  StreamSubscription<Task>? _taskSubscription;
  late Task _task;
  Timer? _debounceTimer;
  bool _isSaving = false;
  late final TaskService _taskService;
  late final AiReviewService _aiReviewService;
  _AiReviewState _aiState = _AiReviewState.loading;
  AIReviewRead? _currentReview;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _task = widget.task!;
    _taskService = widget.taskService ?? getIt<TaskService>();
    _aiReviewService = widget.aiReviewService ?? getIt<AiReviewService>();
    _nameController = TextEditingController(text: _task.name);
    _descriptionController = TextEditingController(text: _task.description);
    _subscribeToTaskUpdates();
    _getTaskDetails();
    _loadReview();
  }

  void _subscribeToTaskUpdates() {
    _taskSubscription?.cancel();
    _taskSubscription = _taskService.taskUpdates
        .where((t) => t.id == _task.id)
        .listen((t) {
      if (!mounted) return;
      setState(() => _task = t);
    });
  }

  @override
  void didUpdateWidget(covariant TaskDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task?.id != oldWidget.task?.id) {
      _debounceTimer?.cancel();
      _task = widget.task!;
      _subscribeToTaskUpdates();
      _nameController.text = _task.name;
      _descriptionController.text = _task.description;
      _getTaskDetails();
      _stopPolling();
      _loadReview();
    }
  }

  Future<void> _getTaskDetails() async {
    if (widget.task == null) return;
    try {
      final detailed = await _taskService.getTaskDetails(taskId: _task.id);
      if (mounted) {
        setState(() {
          _nameController.text = detailed.name;
          _descriptionController.text = detailed.description;
        });
      }
    } catch (e) {
      logger.e('Ошибка загрузки деталей задачи: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _taskSubscription?.cancel();
    super.dispose();
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
    final review = await _aiReviewService.getActiveTaskReview(_task.id);
    if (!mounted) return;
    setState(() {
      _currentReview = review;
      _aiState = review != null ? _AiReviewState.hasReview : _AiReviewState.empty;
    });
  }

  Future<void> _startReview() async {
    if (!mounted) return;
    setState(() => _aiState = _AiReviewState.running);
    try {
      final celeryId = await _aiReviewService.runTaskReview(_task.id);
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
    showDialog(
      context: context,
      builder: (_) => AiReviewHistoryModal(taskId: _task.id),
    );
  }

  Future<void> _performUpdate(Task updatedTask) async {
    if (widget.onTaskUpdated == null) return;
    setState(() => _isSaving = true);
    try {
      await Future.wait([
        widget.onTaskUpdated!(updatedTask),
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
    if (widget.task == null) return;
    _performUpdate(_task.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    ));
  }

  void _toggleStatus() {
    final isDone = _task.status == 'DONE';
    _performUpdate(_task.copyWith(
      status: isDone ? 'TODO' : 'DONE',
      closedAt: isDone ? null : DateTime.now(),
    ));
  }

  void _changeProject(String? newProjectId) {
    if (newProjectId == null) return;
    _performUpdate(_task.copyWith(projectId: newProjectId));
  }

  Future<void> _changePlannedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _task.plannedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final newDate = DateTime(picked.year, picked.month, picked.day, 12, 0);
      _performUpdate(_task.copyWith(plannedAt: newDate));
    }
  }

  Future<void> _clearPlannedDate() async {
    final previous = _task;
    setState(() => _task = _task.copyWithClearedPlannedAt());
    try {
      await _taskService.patchTaskFields(_task.id, {'planned_at': null});
    } catch (_) {
      if (mounted) {
        setState(() => _task = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить')),
        );
      }
    }
  }

  Future<void> _clearProject() async {
    final previous = _task;
    setState(() => _task = _task.copyWithClearedProjectId());
    try {
      await _taskService.patchTaskFields(_task.id, {'project_id': null});
    } catch (_) {
      if (mounted) {
        setState(() => _task = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить')),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    if (widget.task == null) return;
    try {
      await _taskService.deleteTask(taskId: _task.id);
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
    final currentProject = widget.projects
        .where((p) => p.id == _task.projectId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название + кнопка закрытия
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => _onFieldChanged(),
                  style: AppTextStyles.inspectorTitle,
                  decoration: const InputDecoration(
                    hintText: 'Название задачи',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
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
                      decoration: BoxDecoration(
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
          const SizedBox(height: 9),
          // Теги: проект + статус
          Row(
            children: [
              if (currentProject != null) ...[
                _ProjectTag(project: currentProject),
                const SizedBox(width: 5),
              ],
              _StatusTag(isDone: _task.status == 'DONE', onTap: _toggleStatus),
            ],
          ),
        ],
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
            label: 'Проект',
            onClear: _task.projectId != null ? _clearProject : null,
            child: widget.projects.isEmpty
                ? Text('—', style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _task.projectId,
                      isDense: true,
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                      items: widget.projects.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Row(children: [
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: ProjectColorData.getColor(
                                context,
                                int.tryParse(p.colorId ?? '0') ?? 0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(p.name, style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary)),
                          ]),
                        );
                      }).toList(),
                      onChanged: _changeProject,
                    ),
                  ),
          ),

          _FieldRow(
            label: 'Дата',
            onClear: _task.plannedAt != null ? _clearPlannedDate : null,
            child: GestureDetector(
              onTap: _changePlannedDate,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  _task.plannedAt != null
                      ? dateFormat.format(_task.plannedAt!)
                      : 'Не задана',
                  style: AppTextStyles.bodyText.copyWith(
                    color: _task.plannedAt != null
                        ? (_task.plannedAt!.isBefore(DateTime.now())
                            ? AppColors.tomato
                            : AppColors.textPrimary)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),

          if (_task.closedAt != null)
            _FieldRow(
              label: 'Завершено',
              child: Text(
                DateFormat('dd MMM yyyy, HH:mm').format(_task.closedAt!),
                style: AppTextStyles.bodyText.copyWith(color: AppColors.green),
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

          // ── Секция: AI Review ──
          if (widget.showAiReview) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _SectionLabel(label: 'AI Review')),
                if (_aiState == _AiReviewState.hasReview)
                  _AiButton(label: 'Обновить', onPressed: _startReview),
              ],
            ),
            const SizedBox(height: 8),
            _buildAiSection(),
          ],

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
                'Ментор анализирует задачу...',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        );
      case _AiReviewState.empty:
        return AiReviewPlaceholder(
          buttonLabel: 'Проверить задачу',
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

  // ─── Футер (статус сохранения) ────────────────────────────────────────────

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
              onTap: _deleteTask,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 15, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Удалить задачу',
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

// ─── Вспомогательные приватные виджеты ───────────────────────────────────────

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

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onClear;
  const _FieldRow({required this.label, required this.child, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: onClear,
              tooltip: 'Очистить',
              color: AppColors.textMuted,
              hoverColor: AppColors.textSecondary.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}

class _ProjectTag extends StatelessWidget {
  final Project project;
  const _ProjectTag({required this.project});

  @override
  Widget build(BuildContext context) {
    final colorIndex = int.tryParse(project.colorId ?? '0') ?? 0;
    final dotColor = ProjectColorData.getColor(context, colorIndex);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          project.name,
          style: AppTextStyles.metaText.copyWith(color: AppColors.textSecondary),
        ),
      ],
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
            color: _isHovered
                ? const Color(0xFFF5D5D0)
                : AppColors.accentLight,
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

class _StatusTag extends StatelessWidget {
  final bool isDone;
  final VoidCallback onTap;
  const _StatusTag({required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isDone ? AppColors.greenLight : AppColors.bgHover,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isDone ? 'Выполнено' : 'В работе',
            style: AppTextStyles.tagLabel.copyWith(
              color: isDone ? AppColors.green : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
