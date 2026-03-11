import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_checkbox.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_due_date.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/ai_score_badge.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final Function(String newStatus) onStatusChanged;
  final VoidCallback? onTap;
  final bool isSelected;
  final int? aiScore;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onStatusChanged,
    this.onTap,
    this.isSelected = false,
    this.aiScore,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.status == 'DONE';
    final hasMeta = widget.task.plannedAt != null;

    final borderColor = widget.isSelected
        ? AppColors.accent
        : _isHovered
            ? AppColors.borderLight
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.bgPanel : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: _isHovered
                ? const [
                    BoxShadow(
                      color: Color(0x172A1F14),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: TaskCheckbox(
                  value: isDone,
                  onChanged: (val) =>
                      widget.onStatusChanged(val ? 'DONE' : 'TODO'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.name,
                      style: AppTextStyles.taskTitle.copyWith(
                        color: isDone
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                    if (hasMeta) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          TaskDueDate(plannedAt: widget.task.plannedAt),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.aiScore != null) ...[
                const SizedBox(width: 9),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AiScoreBadge(score: widget.aiScore),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
