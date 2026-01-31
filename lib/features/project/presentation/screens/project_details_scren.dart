import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
// Импортируем наш универсальный виджет!
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  final TaskService taskService; // Создаем экземпляр сервиса
  final Function(Task)? onTaskTap;

  ProjectDetailsScreen({
    super.key,
    required this.project,
    TaskService? service,
    this.onTaskTap,
  }) : taskService = service ?? TaskService();

  @override
  Widget build(BuildContext context) {
    // Вся работа - это вернуть и настроить TaskListView!
    logger.i('Открыт проект: ${project.name} (ID: ${project.id})');
    return TaskListView(
      key: ValueKey(project.id),
      title: project.name, // Используем имя проекта как заголовок
      fetcher: () => taskService.getTasksByProject(projectId: project.id),
      creator: (title) =>
          taskService.createTask(projectId: project.id, taskName: title),
      emptyListMessage: "В этом проекте пока нет задач. Добавьте первую!",
      onTaskTap: onTaskTap,
      service: taskService,
    );
  }
}
