import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';
// Дебаг
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class TaskDetailView extends StatefulWidget {
  final Task? task;
  final List<Project> projects;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final Future<void> Function(Task updatedTask)? onTaskUpdated;
  final TaskService? taskService;

  const TaskDetailView({
    super.key,
    this.task,
    this.projects = const [],
    this.onClose,
    this.onDelete,
    this.onTaskUpdated,
    this.taskService,
  });

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  StreamSubscription<Task>? _taskSubscription;
  late Task _task;
  Timer? _debounceTimer;

  bool _isSaving = false;
  late final TaskService _taskService;

  Future<void> _performUpdate(Task updatedTask) async {
    if (widget.onTaskUpdated == null) return;

    setState(() {
      _isSaving = true; // Показываем крутилку
    });

    try {
      // Ждем, пока HomeShellScreen сходит на сервер
      await Future.wait([
        // 1. Реальная работа (отправка на бэк)
        widget.onTaskUpdated!(updatedTask),

        // 2. Искусственная пауза (минимум 800мс или 1 сек, чтобы глаз заметил)
        Future.delayed(const Duration(milliseconds: 800)),
      ]);
    } catch (e) {
      // Ошибки обработает родитель, но нам надо убрать крутилку
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Прячем крутилку
        });
      }
    }
  }

  void _subscribeToTaskUpdates() {
    // 1. Обязательно отменяем старую подписку, если она была
    _taskSubscription?.cancel();

    // 2. Создаем новую, которая слушает ID текущей (новой) задачи
    _taskSubscription = _taskService.taskUpdates
        .where((updatedTask) => updatedTask.id == _task.id)
        .listen(_onTaskUpdated);
  }

  @override
  void initState() {
    super.initState();
    _task = widget.task!;
    _taskService = widget.taskService ?? getIt<TaskService>();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _subscribeToTaskUpdates();
    _getTaskDetails();
    _updateControllers();
  }

  void _onTaskUpdated(Task updatedTask) {
    if (!mounted) return;
    setState(() {
      _task = updatedTask;
    });
  }

  // Если родитель передал новую задачу (пользователь кликнул на другую строку),
  // мы должны обновить текст в полях.
  @override
  void didUpdateWidget(covariant TaskDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если ID изменился (пользователь выбрал другую задачу)
    if (widget.task?.id != oldWidget.task?.id) {
      // 1. Отменяем старые таймеры
      _debounceTimer?.cancel();

      // 2. ВАЖНО: Явно обновляем локальную переменную _task на новую
      _task = widget.task!;

      // 3. ВАЖНО: Переподписываемся на события новой задачи
      _subscribeToTaskUpdates();

      // 4. Обновляем контроллеры (теперь они возьмут данные из новой _task)
      _updateControllers();

      // 5. Загружаем полные данные с сервера
      _getTaskDetails();
    }
  }

  Future<void> _getTaskDetails() async {
    logger.i('Get task details');
    logger.i('Projects - ${widget.projects.length}');
    if (widget.task == null) return;
    setState(() {});
    try {
      final detailedTask = await _taskService.getTaskDetails(taskId: _task.id);
      if (mounted) {
        setState(() {
          // Обновляем контроллеры
          logger.i('Update controllers');
          _nameController.text = detailedTask.name;
          _descriptionController.text = detailedTask.description;
        });
      }
    } catch (e) {
      // Ошибка загрузки деталей задачи
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка загрузки задачи: $e')));
        });
      }
    }
  }

  void _updateControllers() {
    if (widget.task != null) {
      // Важно: ставим курсор, чтобы не сбивался, но тут просто обновляем текст
      _nameController.text = _task.name;
      _descriptionController.text = _task.description;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _taskSubscription?.cancel();
    super.dispose();
  }

  // Логика автосохранения
  void _onFieldChanged() {
    // 1. Отменяем предыдущий таймер, если пользователь продолжает печатать
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // 2. Запускаем новый таймер на 2 секунды
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
      _saveChanges();
    });
  }

  // Метод отправки изменений (вызывается таймером или сменой фокуса)
  void _saveChanges() {
    if (widget.task == null) return;

    // Собираем новую версию задачи
    // (В реале лучше слать только diff, но пока обновим объект целиком локально)
    final updatedTask = _task.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      // Остальные поля пока старые
    );

    // Вызываем коллбек родителя, который дернет API
    _performUpdate(updatedTask);
  }

  // Изменение проекта (без таймера, сразу сохраняем)
  void _changeProject(String? newProjectId) {
    if (widget.task == null || newProjectId == null) return;
    final updatedTask = _task.copyWith(projectId: newProjectId);
    _performUpdate(updatedTask);
  }

  // Изменение даты (без таймера, сразу сохраняем)
  Future<void> _changePlannedDate(BuildContext context) async {
    if (widget.task == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _task.plannedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Добавляем время (пока ставим конец дня или текущее)
      final newDate = DateTime(picked.year, picked.month, picked.day, 12, 0);
      final updatedTask = _task.copyWith(plannedAt: newDate);
      _performUpdate(updatedTask);
    }
  }

  Future<void> _deleteTask() async {
    if (widget.task == null) return;

    try {
      await _taskService.deleteTask(taskId: _task.id);
      if (mounted && widget.onDelete != null) {
        widget.onDelete!();
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка удаления задачи: $e')));
        });
      }
    }
  }

  void _toggleStatus(bool? isDone) {
    if (widget.task == null || isDone == null) return;

    final newStatus = isDone ? 'DONE' : 'TODO';
    // Локально обновляем дату завершения для мгновенного отклика UI
    final newClosedAt = isDone ? DateTime.now() : null;

    final updatedTask = _task.copyWith(
      status: newStatus,
      closedAt: newClosedAt,
    );

    _performUpdate(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    // Находим текущий проект для Dropdown
    logger.i('Current project id is ${_task.projectId}');
    final currentProjectId = _task.projectId;

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
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _deleteTask,
                  ),
                ],
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- СКРОЛЛЯЩИЙСЯ КОНТЕНТ ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // 1. ВЫБОР ПРОЕКТА (DROPDOWN)
                DropdownButtonFormField<String>(
                  initialValue:
                      currentProjectId, // Если null, будет выбрано "Без проекта" (если добавить такой item)
                  decoration: const InputDecoration(
                    labelText: 'Проект',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: widget.projects.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: ProjectColorData.getColor(
                              context,
                              int.tryParse(p.colorId ?? '0') ?? 0,
                            ),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(p.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _changeProject,
                ),

                const SizedBox(height: 24),

                // 2. НАЗВАНИЕ (TextField)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                      // 2.1
                      child: Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          shape: const CircleBorder(),
                          value: _task.status == 'DONE',
                          onChanged: _toggleStatus,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        onChanged: (_) =>
                            _onFieldChanged(), // Запускаем дебаунс
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Название задачи',
                          border: InputBorder
                              .none, // Убираем рамку, чтобы было чисто
                        ),
                        maxLines: null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. ДАТА (Интерактивная строка)
                InkWell(
                  onTap: () => _changePlannedDate(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _task.plannedAt != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(_task.plannedAt!)
                              : 'Добавить плановую дату завершения',
                          style: TextStyle(
                            color: _task.plannedAt != null
                                ? _task.plannedAt!.isBefore(DateTime.now())
                                      ? Colors.deepOrange[700]
                                      : Colors.blueGrey[800]
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Доп. даты: завершено
                if (_task.closedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildDateRow(
                    context,
                    'Завершено',
                    _task.closedAt!,
                    isDone: true,
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // 4. ОПИСАНИЕ (TextField)
                TextField(
                  controller: _descriptionController,
                  onChanged: (_) => _onFieldChanged(),
                  decoration: const InputDecoration(
                    hintText: 'Добавьте описание...',
                    border: InputBorder.none,
                  ),
                  maxLines: null, // Растягивается
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Сохранение...',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey, // Делаем нейтральным цветом
                    ),
                  ),
                ],
              ),
            )
          else
            // Можно показывать "Сохранено" на пару секунд,
            // но пока просто пустой отступ для красоты
            const SizedBox(height: 1),
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
