import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_base.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/quick_add_task_bar.dart';

// Определяем тип для функции-загрузчика
typedef TasksFetcher = Future<List<Task>> Function();
typedef TaskCreator = Future<Task> Function(String title);

class TaskListView extends StatefulWidget {
  final String title; // Заголовок экрана
  final TasksFetcher fetcher; // Функция для загрузки задач
  final TaskCreator creator; // Функция для создания задачи
  final String emptyListMessage; // Сообщение для пустого списка
  final Function(Task)? onTaskTap; // Обработчик нажатия на задачу
  final TaskService? service;

  const TaskListView({
    super.key,
    required this.title,
    required this.fetcher,
    required this.creator,
    required this.emptyListMessage,
    this.onTaskTap,
    this.service,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  bool _isLoading = true;
  String? _error;
  List<Task> _tasks = [];
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _taskService = widget.service ?? TaskService();
    _fetchTasks();
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

  Future<void> _handleAddTask(String taskName) async {
    // Функция для обработки добавления новой задачи
    try {
      final newTask = await widget.creator(taskName);
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
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    return TaskListBase(
      tasks: _tasks,
      onTaskStatusChanged: _handleStatusUpdate,
      emptyListMessage:
          widget.emptyListMessage, // Используем переданное сообщение
      onTaskTap: widget.onTaskTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Используем переданный заголовок
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          QuickAddTaskBar(onTaskSubmitted: _handleAddTask),
        ],
      ),
    );
  }
}
