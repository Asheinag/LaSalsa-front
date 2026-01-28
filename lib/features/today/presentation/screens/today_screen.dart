import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';

class TodayScreen extends StatelessWidget {
  // Добавляем поле для сервиса
  final TaskService taskService;

  // В конструкторе принимаем его опционально.
  // Если передали (в тесте) - берем его.
  // Если нет (в приложении) - создаем новый TaskService().
  TodayScreen({super.key, TaskService? service})
    : taskService = service ?? TaskService();

  @override
  Widget build(BuildContext context) {
    // Просто создаем и настраиваем наш универсальный виджет
    return TaskListView(
      key: const ValueKey('today_screen'),
      title: 'Задачи на сегодня',
      // Передаем саму функцию, которую нужно вызвать для загрузки
      fetcher: () => taskService.getTodayTasks(offset: '0', limit: '20'),
      creator: (title) {
        final now = DateTime.now();
        return taskService.createTask(
          taskName: title,
          plannedAt: DateTime(now.year, now.month, now.day, 12, 00, 00),
        );
      },
      emptyListMessage: 'На сегодня всё! Отличная работа!',
    );
  }
}
