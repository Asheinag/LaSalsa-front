import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';
// // Дебаг
// import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class ProjectDetailsView extends StatefulWidget {
  final Project? project;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final ProjectService? projectService;
  final Future<void> Function(Project updatedProject)? onProjectUpdated;
  const ProjectDetailsView({
    super.key,
    this.project,
    this.onClose,
    this.onDelete,
    this.projectService,
    this.onProjectUpdated,
  });

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  late final ProjectService _projectService;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorId = 0;
  Timer? _debounceTimer;
  bool _isSaving = false;

  Future<void> _performUpdate(Project updatedProject) async {
    if (widget.onProjectUpdated == null) return;

    setState(() {
      _isSaving = true; // Показываем крутилку
    });

    try {
      // Ждем, пока HomeShellScreen сходит на сервер
      await Future.wait([
        // 1. Реальная работа (отправка на бэк)
        widget.onProjectUpdated!(updatedProject),

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _getProjectDetails();
    _projectService = widget.projectService ?? getIt<ProjectService>();
  }

  Future<void> _deleteProject() async {
    if (widget.project == null) return;

    try {
      await _projectService.deleteProject(projectId: widget.project!.id);
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

  Future<void> _getProjectDetails() async {
    if (widget.project == null) return;
    setState(() {});
    if (mounted) {
      setState(() {
        // Обновляем контроллеры
        _nameController.text = widget.project!.name;
        _descriptionController.text = widget.project!.description ?? '';
        _selectedColorId = int.tryParse(widget.project!.colorId ?? '0') ?? 0;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProjectDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project?.id != oldWidget.project?.id) {
      _updateData();
    }
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

  void _saveChanges() {
    if (widget.project == null) return;

    // Собираем новую версию задачи
    // (В реале лучше слать только diff, но пока обновим объект целиком локально)
    final updatedTask = widget.project!.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      // Остальные поля пока старые
    );

    // Вызываем коллбек родителя, который дернет API
    _performUpdate(updatedTask);
  }

  void _changeColor(int newColorId) {
    if (widget.project == null) return;
    final updatedProject = widget.project!.copyWith(
      colorId: newColorId.toString(),
    );
    _performUpdate(updatedProject);
  }

  void _updateData() {
    if (widget.project == null) return;

    // --- НАЗВАНИЕ (Обязательное) ---
    if (_nameController.text != widget.project!.name) {
      _nameController.text = widget.project!.name;
    }

    // --- ОПИСАНИЕ (Необязательное) ---
    // 1. Берем значение или пустую строку
    final newDescription = widget.project!.description ?? '';

    // 2. Сравниваем (чтобы не сбивать курсор и не перерисовывать зря)
    if (_descriptionController.text != newDescription) {
      _descriptionController.text = newDescription;
    }
    // 3. Обновляем цвет при смене проекта
    final newColorId = int.tryParse(widget.project!.colorId ?? '0') ?? 0;
    if (_selectedColorId != newColorId) {
      _selectedColorId = newColorId;
    }
  }

  // Изменение даты (без таймера, сразу сохраняем)
  Future<void> _changeDeadline(BuildContext context) async {
    if (widget.project == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: widget.project!.deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Добавляем время (пока ставим конец дня или текущее)
      final newDate = DateTime(picked.year, picked.month, picked.day, 12, 0);
      final updatedTask = widget.project!.copyWith(deadline: newDate);
      _performUpdate(updatedTask);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
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
                    'Детали проекта',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.grey),
                  ),
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _deleteProject,
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
                // 2. НАЗВАНИЕ (TextField)  и Цвет
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedColorId,
                      underline: const SizedBox.shrink(),
                      isDense: true, // Уменьшает высоту
                      icon:
                          const SizedBox.shrink(), // Скрываем стрелку для минимальной ширины
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedColorId = newValue;
                            _changeColor(newValue);
                          });
                        }
                      },
                      items: List.generate(
                        ProjectColorData.palette.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Icon(
                            Icons.circle,
                            color: ProjectColorData.getColor(context, i),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        onChanged: (_) => _onFieldChanged(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Название проекта',
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
                  onTap: () => _changeDeadline(context),
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
                          widget.project!.deadline != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(widget.project!.deadline!)
                              : 'Добавить плановую дату завершения',
                          style: TextStyle(
                            color: widget.project!.deadline != null
                                ? widget.project!.deadline!.isBefore(
                                        DateTime.now(),
                                      )
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
                if (widget.project!.updatedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildDateRow(
                    context,
                    'Обновлено',
                    widget.project!.updatedAt!,
                    isDone: true,
                  ),
                ],

                const SizedBox(height: 32),
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
          ),
        ),
      ],
    );
  }
}
