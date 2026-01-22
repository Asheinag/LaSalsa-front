import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // То же самое, но с другими настройками
    return TaskListView(
      key: const ValueKey('inbox_screen'),
      title: 'Входящие',
      // Передаем ДРУГУЮ функцию для загрузки
      fetcher: () => TaskService().getTasks(offset: '0', limit: '20'),
      emptyListMessage: 'Вообще нет задач! Вы сделали всё!',
    );
  }
}
