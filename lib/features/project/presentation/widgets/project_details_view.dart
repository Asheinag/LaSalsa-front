import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
// import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';

class ProjectDetailsView extends StatefulWidget {
  final Project? project;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final ProjectService? projectService;
  const ProjectDetailsView({
    super.key,
    this.project,
    this.onClose,
    this.onDelete,
    this.projectService,
  });

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  late final ProjectService _projectService;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _getProjectDetails();
    _projectService = widget.projectService ?? getIt<ProjectService>();
  }

  Future<void> _deleteTask() async {
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
                // 2. НАЗВАНИЕ (TextField)
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Название проекта',
                    border: InputBorder.none, // Убираем рамку, чтобы было чисто
                  ),
                  maxLines: null,
                ),

                const SizedBox(height: 16),
                // 3. ДАТА (Интерактивная строка)
                InkWell(
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
                // 4. ОПИСАНИЕ (TextField)
                TextField(
                  controller: _descriptionController,
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
        ],
      ),
    );
  }
}
