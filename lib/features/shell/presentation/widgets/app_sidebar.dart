import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class AppSidebar extends StatefulWidget {
  final List<Project> projects; // Список проектов
  final Function(String pageId, {dynamic args})
  onPageSelected; // Коллбэк при выборе страницы
  final Function(Project newProject)?
  onProjectCreated; // Коллбэк при создании нового проекта
  const AppSidebar({
    super.key,
    required this.onPageSelected,
    required this.projects,
    this.onProjectCreated,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final ProjectService _projectService = ProjectService();
  bool _isCreatingProject = false; // Флаг, показывающий поле ввода
  final _newProjectController =
      TextEditingController(); // Контроллер для создания нового проекта

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
          widget.onProjectCreated?.call(
            newProject,
          ); // 2. Вызываем коллбэк с новым проектом
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
              onTap: () => setState(() => _isCreatingProject = true),
            ),

            const Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: _isCreatingProject
                    ? projectsList.length + 1
                    : projectsList.length,
                itemBuilder: (context, index) {
                  // Если это "фальшивый" элемент
                  if (_isCreatingProject && index == projectsList.length) {
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
                  final project = projectsList[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.circle,
                      color: Colors.grey,
                      size: 14,
                    ),
                    title: Text(project.name),
                    onTap: () {
                      // ИЗМЕНЕНИЕ 4: Передаем ID 'project' и сам объект проекта в args
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
