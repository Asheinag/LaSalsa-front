import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/api/task_api.dart';
import '../models/task.dart';
import '../widgets/active_task_list.dart';
import '../widgets/completed_task_list.dart';
import '../widgets/task_input_field.dart';
import '../utils/logger.dart';

class TaskListScreen extends StatefulWidget {
  final TaskApi taskApi;
  const TaskListScreen({super.key, required this.taskApi});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> activeTasks = [];
  List<Task> doneTasks = [];
  DateTime? _plannedDate;

  final TextEditingController _newTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final result = await widget.taskApi.fetchTasks();
      setState(() {
        activeTasks = result.where((t) => t.status != 'DONE').toList();
        doneTasks = result.where((t) => t.status == 'DONE').toList();
      });
    } catch (e) {
      logger.e('Ошибка загрузки задач');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _plannedDate) {
      setState(() {
        _plannedDate = picked;
      });
    }
  }

  void _updateTaskInList(Task updatedTask) {
    setState(() {
      activeTasks.removeWhere((t) => t.id == updatedTask.id);
      doneTasks.removeWhere((t) => t.id == updatedTask.id);

      if (updatedTask.status == 'DONE') {
        doneTasks.add(updatedTask);
      } else {
        activeTasks.add(updatedTask);
      }
    });
  }

  void _addTask(String name, DateTime? plannedAt) async {
    if (name.isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: '',
      status: 'TODO',
      plannedAt: plannedAt,
    );

    try {
      Task resultTask = await widget.taskApi.addTask(newTask);
      setState(() {
        activeTasks.add(resultTask);
        _newTaskController.clear();
        _plannedDate = null;
      });
    } catch (e) {
      logger.e('Ошибка добавления задачи');
    }
  }

  void _toggleStatus(Task task, bool? checked) async {
    String newStatus = checked == true ? 'DONE' : 'TODO';
    String previousStatus = task.status;
    Task? originalTask; // Для хранения оригинальной задачи перед изменением UI
    int? originalIndex; // Добавляем переменную для хранения индекса

    setState(() {
      if (checked == true) {
        originalIndex = activeTasks.indexOf(
          task,
        ); // Получаем индекс перед удалением
        originalTask = task; // Сохраняем оригинал
        activeTasks.removeWhere((t) => t.id == task.id);
        doneTasks.add(task.copyWith(status: newStatus)); // Обновляем UI
      } else {
        originalIndex = doneTasks.indexOf(
          task,
        ); // Получаем индекс перед удалением
        originalTask = task; // Сохраняем оригинал
        doneTasks.removeWhere((t) => t.id == task.id);
        activeTasks.insert(0, task.copyWith(status: newStatus)); // Обновляем UI
      }
    });

    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Задача ${checked == true ? 'выполнена' : 'возвращена'}!',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            setState(() {
              if (checked == true && originalIndex != null) {
                doneTasks.removeWhere((t) => t.id == task.id);
                activeTasks.insert(
                  originalIndex!,
                  originalTask!.copyWith(status: previousStatus),
                ); // Вставляем на прежнее место
              } else if (originalIndex != null) {
                activeTasks.removeWhere((t) => t.id == task.id);
                doneTasks.insert(
                  originalIndex!,
                  originalTask!.copyWith(status: previousStatus),
                ); // Вставляем на прежнее место
              }
            });
          },
        ),
      ),
    );

    // Ждем закрытия SnackBar
    final reason = await snackBarController.closed;

    // Если SnackBar закрылся не из-за действия "Отменить", отправляем изменения на бэк
    if (reason != SnackBarClosedReason.action) {
      try {
        await widget.taskApi.setTaskStatus(task.id, newStatus);
      } catch (e) {
        logger.e('Не удалось обновить статус задачи');
        if (originalIndex != null && originalTask != null) {
          setState(() {
            if (newStatus == 'DONE') {
              doneTasks.removeWhere((t) => t.id == task.id);
              activeTasks.insert(
                originalIndex!,
                originalTask!.copyWith(status: previousStatus),
              );
            } else {
              activeTasks.removeWhere((t) => t.id == task.id);
              doneTasks.insert(
                originalIndex!,
                originalTask!.copyWith(status: previousStatus),
              );
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка обновления задачи')),
        );
      }
    }
  }

  void _reorderActiveTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final task = activeTasks.removeAt(oldIndex);
      activeTasks.insert(newIndex, task);
    });
  }

  void _dismissTask(int index) async {
    final removedTask = activeTasks[index];
    setState(() => activeTasks.removeAt(index));
    try {
      await widget.taskApi.deleteTask(removedTask.id);
    } catch (e) {
      logger.e('Ошибка при удалении задачи');
      setState(() => activeTasks.insert(index, removedTask));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить задачу')),
      );
    }
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final String userDisplayName =
        user.displayName ?? user.email ?? 'Пользователь';
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaSalsa – задачи'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                userDisplayName,
                style: const TextStyle(fontSize: 16), // Можете настроить стиль
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () {
              // Просто вызываем signOut, а AuthGate сделает остальное
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ActiveTaskList(
                  tasks: activeTasks,
                  onStatusToggle: _toggleStatus,
                  onDismiss: _dismissTask,
                  onReorder: _reorderActiveTasks,
                  taskApi: widget.taskApi,
                  onTaskUpdated: _updateTaskInList,
                ),
                const SizedBox(height: 24),
                CompletedTaskList(
                  tasks: doneTasks,
                  onStatusToggle: _toggleStatus,
                  taskApi: widget.taskApi,
                  onTaskUpdated: _updateTaskInList,
                ),
              ],
            ),
          ),
          const Divider(),
          TaskInputField(
            controller: _newTaskController,
            onAdd: _addTask,
            selectedDate: _plannedDate,
            onSelectDate: () => _selectDate(context),
          ),
        ],
      ),
    );
  }
}
