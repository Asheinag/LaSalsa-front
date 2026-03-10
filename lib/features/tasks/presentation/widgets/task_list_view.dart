import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_base.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/quick_add_task_bar.dart';

// Определяем тип для функции-загрузчика
typedef TasksFetcher = Future<List<Task>> Function();
typedef TaskCreator = Future<Task> Function(String title, DateTime? plannedAt);

class TaskListView extends StatefulWidget {
  final String title; // Заголовок экрана
  final TasksFetcher fetcher; // Функция для загрузки задач
  final TaskCreator creator; // Функция для создания задачи
  final String emptyListMessage; // Сообщение для пустого списка
  final Function(Task)? onTaskTap; // Обработчик нажатия на задачу
  final TaskService? service;
  final String? initialValue;
  final DateTime? initialDate;
  final bool hideCompleted; // Скрывать выполненные задачи по умолчанию

  const TaskListView({
    super.key,
    required this.title,
    required this.fetcher,
    required this.creator,
    required this.emptyListMessage,
    this.onTaskTap,
    this.service,
    this.initialValue,
    this.initialDate,
    this.hideCompleted = false,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  bool _isLoading = true;
  String? _error;
  List<Task> _tasks = [];
  bool _showCompleted = false;
  late final TaskService _taskService;
  StreamSubscription<Task>? _taskSubscription;
  StreamSubscription<String>? _taskDeleteSubscription;

  @override
  void initState() {
    super.initState();
    _taskService = widget.service ?? TaskService();
    _fetchTasks();
    _taskSubscription = _taskService.taskUpdates.listen(_onTaskUpdated);
    _taskDeleteSubscription = _taskService.taskDeletions.listen(_onTaskDeleted);
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _taskDeleteSubscription?.cancel();
    super.dispose();
  }

  void _onTaskUpdated(Task updatedTask) {
    if (!mounted) return;
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        // Если задана начальная дата (например, для списка "Сегодня"),
        // проверяем, совпадает ли дата задачи с ней.
        if (widget.initialDate != null) {
          final taskDate = updatedTask.plannedAt;
          final listDate = widget.initialDate!;
          final isSameDay =
              taskDate != null &&
              taskDate.year == listDate.year &&
              taskDate.month == listDate.month &&
              taskDate.day == listDate.day;
          if (!isSameDay) {
            _tasks.removeAt(index);
            return;
          }
        }
        _tasks[index] = updatedTask;
      }
    });
  }

  void _onTaskDeleted(String taskId) {
    if (!mounted) return;
    setState(() {
      _tasks.removeWhere((t) => t.id == taskId);
    });
  }

  Future<void> _fetchTasks() async {
    // Теперь мы вызываем ту функцию, которую нам передали
    try {
      final tasks = await widget.fetcher();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить задачи.';
          _isLoading = false;
        });
      }
      logger.e('Ошибка при загрузке задач для "${widget.title}": $e');
    }
  }

  Future<void> _handleStatusUpdate(Task task, String newStatus) async {
    // Функция для обработки изменения статуса задачи
    try {
      // 1. Вызываем сервис для обновления задачи на бэкенде
      final updatedTask = await _taskService.updateTaskStatus(
        taskId: task.id,
        taskStatus: newStatus,
      );

      // 2. Обновляем наш локальный список задач
      setState(() {
        // Находим индекс старой задачи в списке
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          // Заменяем старую задачу на обновленную, полученную с сервера
          _tasks[index] = updatedTask;
        }
      });
    } catch (e) {
      // Можно показать ошибку пользователю
      logger.e('Не удалось обновить задачу: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка обновления задачи')),
        );
      }
    }
  }

  Future<void> _handleAddTask(String title, DateTime? date) async {
    if (title.isEmpty) return;
    // Функция для обработки добавления новой задачи
    try {
      final newTask = await widget.creator(title, date);
      setState(() {
        _tasks.insert(0, newTask); // Добавляем новую задачу в начало списка
      });
    } catch (e) {
      logger.e('Не удалось создать задачу: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка создания задачи')));
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: AppTextStyles.bodyText.copyWith(color: AppColors.accent)),
      );
    }

    if (!widget.hideCompleted) {
      return TaskListBase(
        tasks: _tasks,
        onTaskStatusChanged: _handleStatusUpdate,
        emptyListMessage: widget.emptyListMessage,
        onTaskTap: widget.onTaskTap,
      );
    }

    final activeTasks = _tasks.where((t) => t.status != 'DONE').toList();
    final doneTasks = _tasks.where((t) => t.status == 'DONE').toList();

    return Column(
      children: [
        Expanded(
          child: TaskListBase(
            tasks: activeTasks,
            onTaskStatusChanged: _handleStatusUpdate,
            emptyListMessage: widget.emptyListMessage,
            onTaskTap: widget.onTaskTap,
          ),
        ),
        if (doneTasks.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _showCompleted = !_showCompleted),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      _showCompleted ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showCompleted
                          ? 'Скрыть выполненные'
                          : 'Выполнено (${doneTasks.length})',
                      style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (doneTasks.isNotEmpty && _showCompleted)
          SizedBox(
            height: 300,
            child: TaskListBase(
              tasks: doneTasks,
              onTaskStatusChanged: _handleStatusUpdate,
              emptyListMessage: '',
              onTaskTap: widget.onTaskTap,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskCount = _tasks.where((t) => t.status != 'DONE').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(taskCount),
        Expanded(child: _buildBody()),
        QuickAddTaskBar(
          onTaskSubmitted: _handleAddTask,
          initialValue: widget.initialValue,
          initialDate: widget.initialDate,
        ),
      ],
    );
  }

  Widget _buildHeader(int taskCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.screenTitle),
                const SizedBox(height: 2),
                Text(
                  '$taskCount активных',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
