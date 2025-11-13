import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Просто создаем и настраиваем наш универсальный виджет
    return TaskListView(
      key: const ValueKey('today_screen'),
      title: 'Задачи на сегодня',
      // Передаем саму функцию, которую нужно вызвать для загрузки
      fetcher: () => TaskService().getTodayTasks(offset: '0', limit: '20'),
      emptyListMessage: 'На сегодня всё! Отличная работа!',
    );
  }
}
