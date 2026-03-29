import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_base.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_item.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/quick_add_task_bar.dart';

typedef TasksFetcher = Future<List<Task>> Function(int offset, int limit);
typedef TaskCreator = Future<Task> Function(String title, DateTime? plannedAt);

class TaskListView extends StatefulWidget {
  final String title;
  final TasksFetcher fetcher;
  final TaskCreator creator;
  final String emptyListMessage;
  final Function(Task)? onTaskTap;
  final TaskService? service;
  final String? initialValue;
  final DateTime? initialDate;
  final bool hideCompleted;
  final bool Function(Task)? removeIf;

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
    this.removeIf,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  List<Task> _tasks = [];
  bool _showCompleted = false;
  late final TaskService _taskService;
  late final ScrollController _scrollController;
  StreamSubscription<Task>? _taskSubscription;
  StreamSubscription<String>? _taskDeleteSubscription;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _taskService = widget.service ?? TaskService();
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchTasks();
    _taskSubscription = _taskService.taskUpdates.listen(_onTaskUpdated);
    _taskDeleteSubscription = _taskService.taskDeletions.listen(_onTaskDeleted);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _taskSubscription?.cancel();
    _taskDeleteSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (widget.hideCompleted) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onTaskUpdated(Task updatedTask) {
    if (!mounted) return;
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        if (widget.removeIf != null && widget.removeIf!(updatedTask)) {
          _tasks.removeAt(index);
          return;
        }
        if (widget.initialDate != null) {
          final taskDate = updatedTask.plannedAt;
          final listDate = widget.initialDate!;
          final isSameDay = taskDate != null &&
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
    setState(() => _tasks.removeWhere((t) => t.id == taskId));
  }

  Future<void> _fetchTasks() async {
    try {
      final limit = widget.hideCompleted ? 9999 : _pageSize;
      final tasks = await widget.fetcher(0, limit);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _hasMore = !widget.hideCompleted && tasks.length == _pageSize;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final newTasks = await widget.fetcher(_tasks.length, _pageSize);
      if (mounted) {
        setState(() {
          _tasks.addAll(newTasks);
          _hasMore = newTasks.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleStatusUpdate(Task task, String newStatus) async {
    try {
      final updatedTask = await _taskService.updateTaskStatus(
        taskId: task.id,
        taskStatus: newStatus,
      );
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) _tasks[index] = updatedTask;
      });
    } catch (e) {
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
    try {
      final newTask = await widget.creator(title, date);
      setState(() => _tasks.insert(0, newTask));
    } catch (e) {
      logger.e('Не удалось создать задачу: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания задачи')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTextStyles.bodyText.copyWith(color: AppColors.accent),
        ),
      );
    }

    // ── Infinite scroll (hideCompleted: false) ──────────────────────────────
    if (!widget.hideCompleted) {
      if (_tasks.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              widget.emptyListMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            ),
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        itemCount: _tasks.length + 1,
        itemBuilder: (context, index) {
          if (index == _tasks.length) {
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (!_hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Все задачи загружены',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          final task = _tasks[index];
          return TaskListItem(
            task: task,
            onStatusChanged: (newStatus) => _handleStatusUpdate(task, newStatus),
            onTap: widget.onTaskTap != null ? () => widget.onTaskTap!(task) : null,
          );
        },
      );
    }

    // ── Режим hideCompleted: true (one-time load, показ выполненных) ────────
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
                      style: AppTextStyles.bodyText
                          .copyWith(color: AppColors.textMuted),
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
