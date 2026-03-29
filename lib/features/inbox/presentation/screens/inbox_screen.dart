import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';

class InboxScreen extends StatelessWidget {
  final Function(Task)? onTaskTap;
  final TaskService taskService;

  InboxScreen({super.key, this.onTaskTap, TaskService? service})
      : taskService = service ?? TaskService();

  @override
  Widget build(BuildContext context) {
    // То же самое, но с другими настройками
    return TaskListView(
      key: const ValueKey('inbox_screen'),
      title: 'Входящие',
      fetcher: (offset, limit) => taskService.getActiveTasks(
        offset: '$offset',
        limit: '$limit',
      ),
      creator: (title, plannedAt) =>
          taskService.createTask(taskName: title, plannedAt: plannedAt),
      emptyListMessage: 'Вообще нет задач! Вы сделали всё!',
      onTaskTap: onTaskTap,
      service: taskService,
    );
  }
}
