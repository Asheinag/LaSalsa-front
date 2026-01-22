import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_item.dart';

class TaskListBase extends StatelessWidget {
  final List<Task> tasks; // Список задач, который нужно отобразить
  final String emptyListMessage; // Сообщение, если список пуст
  final Function(Task task, String newStatus) onTaskStatusChanged;

  const TaskListBase({
    super.key,
    required this.tasks,
    required this.onTaskStatusChanged,
    this.emptyListMessage = "Здесь пока нет задач",
  });

  @override
  Widget build(BuildContext context) {
    // Если список задач пуст, показываем сообщение
    if (tasks.isEmpty) {
      return Center(child: Text(emptyListMessage));
    }

    // Если в списке есть задачи, используем ListView.builder
    // Это самый эффективный способ отображения списков
    return ListView.builder(
      // Указываем, сколько всего элементов будет в списке
      itemCount: tasks.length,
      // itemBuilder - это функция, которая будет вызвана для каждого элемента.
      // Она строит виджет для элемента с определенным `index`.
      itemBuilder: (BuildContext context, int index) {
        // 1. Берем конкретную задачу из списка по ее индексу
        final task = tasks[index];
        // 2. Возвращаем наш виджет TaskListItem, передав в него эту задачу
        return TaskListItem(
          task: task,
          onStatusChanged: (newStatus) {
            onTaskStatusChanged(task, newStatus);
          },
        );
      },
    );
  }
}
