import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final Function(String newStatus) onStatusChanged;
  final VoidCallback? onTap;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onStatusChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      leading: Checkbox(
        value: task.status == 'DONE',
        onChanged: (bool? value) {
          if (value != null) {
            final newStatus = value ? 'DONE' : 'TODO';
            onStatusChanged(newStatus);
          }
        },
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.status == 'DONE'
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: task.plannedAt != null
          ? Text(
              'Запланировано на: ${task.plannedAt!.toLocal().toString().substring(0, 10)}',
            )
          : null,
      trailing: task.parentId != null ? const Icon(Icons.call_split) : null,
    );
  }
}
