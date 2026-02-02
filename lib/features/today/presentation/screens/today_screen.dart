import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';

class TodayScreen extends StatelessWidget {
  // Добавляем поле для сервиса
  final TaskService taskService;
  final Function(Task)? onTaskTap;

  // В конструкторе принимаем его опционально.
  // Если передали (в тесте) - берем его.
  // Если нет (в приложении) - создаем новый TaskService().
  TodayScreen({super.key, TaskService? service, this.onTaskTap})
      : taskService = service ?? TaskService();

  @override
  Widget build(BuildContext context) {
    // Просто создаем и настраиваем наш универсальный виджет
    return TaskListView(
      key: const ValueKey('today_screen'),
      title: 'Задачи на сегодня',
      initialDate: DateTime.now(),
      // Передаем саму функцию, которую нужно вызвать для загрузки
      fetcher: () => taskService.getTodayTasks(offset: '0', limit: '20'),
      creator: (title, plannedAt) {
        final now = DateTime.now();
        return taskService.createTask(
          taskName: title,
          plannedAt: plannedAt ?? DateTime(now.year, now.month, now.day, 12),
        );
      },
      emptyListMessage: 'На сегодня всё! Отличная работа!',
      onTaskTap: onTaskTap,
      service: taskService,
    );
  }
}
