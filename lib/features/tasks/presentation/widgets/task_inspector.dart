import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';

class TaskInspector extends StatelessWidget {
  final Task? task;
  final List<Project> projects;
  final VoidCallback? onClose; // Кнопка закрыть (для мобилок или если надоело)

  const TaskInspector({
    super.key,
    this.task,
    this.projects = const [],
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Состояние, когда задача не выбрана
    if (task == null) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Выберите задачу,\nчтобы увидеть детали',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final t = task!;

    String? projectName;
    if (t.projectId != null) {
      try {
        final project = projects.firstWhere((p) => p.id == t.projectId);
        projectName = project.name;
      } catch (e) {
        projectName = 'Неизвестный проект';
      }
    }
    // Основная верстка деталей
    return Container(
      color: Colors.white, // Фон инспектора
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- ШАПКА ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Детали задачи',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.grey),
                  ),
                ),
                if (onClose != null)
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- СКРОЛЛЯЩИЙСЯ КОНТЕНТ ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // 1. Проект (пока ID, позже сделаем подстановку имени)
                if (t.projectId != null) ...[
                  Chip(
                    avatar: const Icon(Icons.folder_open, size: 16),
                    label: Text('$projectName'),
                    backgroundColor: Colors.blue[50],
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Название задачи
                SelectableText(
                  // Чтобы можно было копировать
                  t.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Даты (Сетка)
                if (t.plannedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildDateRow(context, 'План', t.plannedAt!),
                ],
                if (t.closedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildDateRow(
                    context,
                    'Завершено',
                    t.closedAt!,
                    isDone: true,
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // 4. Описание
                Text(
                  'ОПИСАНИЕ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.description.isNotEmpty ? t.description : 'Нет описания...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: t.description.isNotEmpty
                        ? Colors.black87
                        : Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    String label,
    DateTime date, {
    bool isDone = false,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm'); // Нужен package:intl
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Text(
          dateFormat.format(date),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDone ? Colors.green[700] : Colors.black87,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
