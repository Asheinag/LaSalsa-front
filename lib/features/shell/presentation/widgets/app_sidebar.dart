import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_scren.dart';

class AppSidebar extends StatefulWidget {
  final Function(Widget) onScreenSelected;

  const AppSidebar({super.key, required this.onScreenSelected});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isLoading = true;
  List<Project> _projects = [];
  final ProjectService _projectService = ProjectService();

  bool _isCreatingProject = false; // Флаг, показывающий поле ввода
  final _newProjectController =
      TextEditingController(); // Контроллер для создания нового проекта

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    // Функция для получения проектов
    try {
      final projects = await _projectService.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      logger.e('Ошибка при загрузке проектов: $e');
    }
  }

  Future<void> _submitNewProject() async {
    final name = _newProjectController.text.trim();

    // Если имя пустое, просто выходим из режима создания
    if (name.isEmpty) {
      setState(() {
        _isCreatingProject = false;
      });
      _newProjectController.clear();
      return; // Выходим из функции
    }

    // Если имя ЕСТЬ, сначала выполняем ВСЮ асинхронную работу
    try {
      final newProject = await _projectService.createProject(name: name);

      // И только ПОСЛЕ успешного await...
      if (mounted) {
        // ...обновляем UI ОДНИМ вызовом setState
        setState(() {
          _isCreatingProject = false; // 1. Прячем TextField
          _projects.add(newProject); // 2. Добавляем новый проект
        });
      }
    } catch (e) {
      logger.e('Не удалось создать проект: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания проекта')),
        );
        // Даже если ошибка, прячем поле
        setState(() {
          _isCreatingProject = false;
        });
      }
    }

    // Очищаем контроллер в самом конце
    _newProjectController.clear(); // Очищаем контроллер
  }

  @override
  void dispose() {
    _newProjectController.dispose(); // Не забываем очищать
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Сегодня'),
              onTap: () {
                widget.onScreenSelected(TodayScreen());
              },
            ),

            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Входящие'),
              onTap: () {
                widget.onScreenSelected(const InboxScreen());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blueGrey),
              title: const Text(
                'Создать проект',
                style: TextStyle(color: Colors.blueGrey),
              ),
              onTap: () {
                setState(() {
                  _isCreatingProject = true;
                });
              },
            ),
            const Divider(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _isCreatingProject
                          ? _projects.length + 1
                          : _projects.length,
                      itemBuilder: (context, index) {
                        // Если это "фальшивый" элемент
                        if (_isCreatingProject && index == _projects.length) {
                          return ListTile(
                            leading: const Icon(
                              Icons.circle,
                              color: Colors.grey,
                              size: 14,
                            ),
                            // Вместо Text показываем TextField
                            title: TextField(
                              controller: _newProjectController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Название проекта',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) =>
                                  _submitNewProject(), // Отправка по Enter
                              onTapOutside: (_) =>
                                  _submitNewProject(), // Отправка по клику в сторону
                            ),
                          );
                        }

                        // В противном случае, это обычный элемент
                        final project = _projects[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.circle,
                            color: Colors.grey,
                            size: 14,
                          ),
                          title: Text(project.name),
                          onTap: () {
                            widget.onScreenSelected(
                              ProjectDetailsScreen(project: project),
                            );
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
