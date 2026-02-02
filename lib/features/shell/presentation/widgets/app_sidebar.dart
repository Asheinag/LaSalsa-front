import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';

class AppSidebar extends StatefulWidget {
  final List<Project> projects;
  final Function(String pageId, {dynamic args}) onPageSelected;
  final Function(Project newProject)? onProjectCreated;
  final ProjectService? projectService;

  const AppSidebar({
    super.key,
    required this.onPageSelected,
    required this.projects,
    this.onProjectCreated,
    this.projectService,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late final ProjectService _projectService;
  bool _isCreatingProject = false;
  final _newProjectController = TextEditingController();
  int _selectedColorId = 0;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? ProjectService();
  }

  Future<void> _submitNewProject() async {
    final name = _newProjectController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _isCreatingProject = false;
      });
      _newProjectController.clear();
      return;
    }

    try {
      final newProject = await _projectService.createProject(
        name: name,
        colorId: _selectedColorId.toString(),
      );

      if (mounted) {
        setState(() {
          _isCreatingProject = false;
          widget.onProjectCreated?.call(
            newProject.copyWith(colorId: _selectedColorId.toString()),
          );
        });
      }
    } catch (e) {
      logger.e('Не удалось создать проект: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания проекта')),
        );
        setState(() {
          _isCreatingProject = false;
        });
      }
    }
    _newProjectController.clear();
  }

  @override
  void dispose() {
    _newProjectController.dispose(); // Не забываем очищать
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsList = widget.projects;
    return SizedBox(
      width: 250,
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Меню',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // --- СЕКЦИЯ "СЕГОДНЯ" ---
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Сегодня'),
              onTap: () {
                // ИЗМЕНЕНИЕ 2: Передаем ID вместо Виджета
                widget.onPageSelected('today');
              },
            ),

            // --- СЕКЦИЯ "ВХОДЯЩИЕ" ---
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Входящие'),
              onTap: () {
                // ИЗМЕНЕНИЕ 3: Передаем ID
                widget.onPageSelected('inbox');
              },
            ),

            const Divider(),

            // --- СЕКЦИЯ "ПРОЕКТЫ" ---
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blueGrey),
              title: const Text(
                'Создать проект',
                style: TextStyle(color: Colors.blueGrey),
              ),
              onTap: () => setState(() {
                _isCreatingProject = true;
                _selectedColorId = 0; // Reset to default color
              }),
            ),

            const Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: _isCreatingProject
                    ? projectsList.length + 1
                    : projectsList.length,
                itemBuilder: (context, index) {
                  if (_isCreatingProject && index == projectsList.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          DropdownButton<int>(
                            value: _selectedColorId,
                            underline: const SizedBox.shrink(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedColorId = newValue;
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
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _newProjectController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Название проекта',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _submitNewProject(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final project = projectsList[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: ProjectColorData.getColor(
                        context,
                        int.tryParse(project.colorId ?? '0') ?? 0,
                      ),
                      size: 14,
                    ),
                    title: Text(project.name),
                    onTap: () {
                      widget.onPageSelected('project', args: project);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
