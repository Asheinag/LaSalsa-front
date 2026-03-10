import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_item.dart';

class TaskListBase extends StatelessWidget {
  final List<Task> tasks;
  final String emptyListMessage;
  final Function(Task task, String newStatus) onTaskStatusChanged;
  final Function(Task)? onTaskTap;
  final Task? selectedTask;

  const TaskListBase({
    super.key,
    required this.tasks,
    required this.onTaskStatusChanged,
    this.emptyListMessage = 'Здесь пока нет задач',
    this.onTaskTap,
    this.selectedTask,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyState(message: emptyListMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          isSelected: selectedTask?.id == task.id,
          onStatusChanged: (newStatus) => onTaskStatusChanged(task, newStatus),
          onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 36,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
