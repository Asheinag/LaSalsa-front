import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
// Импортируем наш универсальный виджет!
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  final TaskService _taskService = TaskService(); // Создаем экземпляр сервиса

  ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Вся работа - это вернуть и настроить TaskListView!
    logger.i('Открты проект: ${project.name} (ID: ${project.id})');
    return TaskListView(
      key: ValueKey(project.id),
      title: project.name, // Используем имя проекта как заголовок
      fetcher: () => _taskService.getTasksByProject(projectId: project.id),
      emptyListMessage: "В этом проекте пока нет задач. Добавьте первую!",
    );
  }
}
