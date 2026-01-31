import 'package:flutter/material.dart';
// Импорты моделей
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
// Импорты виджетов
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_inspector.dart';
// Импорты сервисов
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
// Импорты экранов
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_scren.dart';
// Дебаг
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  String _selectedPageId = 'today'; // Задачем начальную страницу - Сегодня
  dynamic _currentPageArgs; // Храним аргументы (например, выбранный проект)
  Task? _selectedTask; // Храним выбранную задачу для третьей колонки
  bool _isLoading = true; // Флаг загрузки проектов
  List<Project> _projects = []; // Список проектов
  final ProjectService _projectService =
      ProjectService(); // Сервис для работы с проектами
  final TaskService _taskService =
      TaskService(); // Сервис для работы с задачами

  @override
  void initState() {
    super.initState();
    _fetchProjects(); // Загружаем при старте приложения
  }

  // Метод загрузки проектов
  Future<void> _fetchProjects() async {
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

  // Метод обновления задачи из инспектора
  Future<void> _handleTaskUpdate(Task updatedTask) async {
    try {
      setState(() {
        _selectedTask = updatedTask;
      });

      await _taskService.updateTask(
        taskId: updatedTask.id,
        name: updatedTask.name,
        description: updatedTask.description,
        projectId: updatedTask.projectId,
        plannedAt: updatedTask.plannedAt,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  // Обработчик переключения страниц (приходит из Sidebar)
  void _onPageChanged(String pageId, {dynamic args}) {
    setState(() {
      _selectedPageId = pageId;
      _currentPageArgs = args;
      _selectedTask = null; // Сбрасываем выбранную задачу при смене раздела
    });
    logger.i('Переключение на страницу: $pageId с аргументами: $args');
  }

  // Метод обработки клика по задаче (вызывается из TodayScreen и др)
  void _handleTaskTap(Task task) {
    setState(() {
      _selectedTask = task;
    });
  }

  // Фабрика экранов
  Widget _buildActiveScreen() {
    switch (_selectedPageId) {
      case 'today':
        logger.i('Построение экрана TodayScreen');
        return TodayScreen(
          onTaskTap: _handleTaskTap, // Подключаем тап!
        );

      case 'inbox':
        logger.i('Построение экрана InboxScreen');
        return InboxScreen(
          onTaskTap: _handleTaskTap, // Подключаем тап!
        );

      case 'project':
        logger.i('Построение экрана ProjectDetailsScreen');
        // Достаем проект из аргументов
        if (_currentPageArgs is Project) {
          return ProjectDetailsScreen(
            project: _currentPageArgs as Project,
            onTaskTap: _handleTaskTap, // Подключаем тап!
          );
        }
        return const Center(child: Text("Ошибка: Проект не выбран"));

      default:
        return const Center(child: Text("404"));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Определяем ширину экрана
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      body: Row(
        children: [
          // 1. Сайдбар
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AppSidebar(
                  projects:
                      _projects, // <-- AppSidebar теперь просто "рисует" их
                  onPageSelected:
                      _onPageChanged, // <-- Передаем метод переключения страниц
                  onProjectCreated: (newProject) {
                    setState(() {
                      _projects.add(newProject);
                    });
                  },
                ),
          const VerticalDivider(width: 1, thickness: 1),

          // 2. Основной контент
          Expanded(flex: 5, child: _buildActiveScreen()),

          // 3. Правая колонка с инспектором задачи
          if (isDesktop) ...[
            // Показываем только на широком экране
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              flex: 2, // Занимает 3 части ширины (чуть уже списка)
              child: TaskInspector(
                task: _selectedTask,
                projects: _projects,
                onClose: () => setState(() => _selectedTask = null),
                onDelete: () => setState(() => _selectedTask = null),
                onTaskUpdated: _handleTaskUpdate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
