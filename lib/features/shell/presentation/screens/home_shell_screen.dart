import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Импорты моделей
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
// Импорты виджетов
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/right_sidebar.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_detail_view.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/widgets/project_details_view.dart';
import 'package:kabachok_lasalsa_front/core/widgets/basic_detail_view.dart';
// Импорты сервисов
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';
// Импорты экранов
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_screen.dart';
// Дебаг
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class HomeShellScreen extends StatefulWidget {
  final ProjectService? projectService;
  final TaskService? taskService;
  final FirebaseAuth? auth;

  const HomeShellScreen({super.key, this.projectService, this.taskService, this.auth});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  Task? _selectedTask; // Храним выбранную задачу для третьей колонки
  Project? _selectedProject; // Храним выбранный проект для второй колонки

  String _selectedPageId = 'today'; // Задачем начальную страницу - Сегодня
  dynamic _currentPageArgs; // Храним аргументы (например, выбранный проект)

  List<Project> _projects = []; // Список проектов

  bool _isLoading = true; // Флаг загрузки проектов
  late final ProjectService _projectService;
  late final TaskService _taskService;
  StreamSubscription<Project>? _projectSubscription;
  StreamSubscription<String>? _projectDeleteSubscription;
  StreamSubscription<String>? _taskDeleteSubscription;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? getIt<ProjectService>();
    _taskService = widget.taskService ?? getIt<TaskService>();
    _fetchProjects(); // Загружаем при старте приложения
    _projectSubscription = _projectService.projectUpdates.listen(
      _onProjectUpdated,
    );
    _projectDeleteSubscription = _projectService.projectDeletions.listen(
      _onProjectDeleted,
    );
    _taskDeleteSubscription = _taskService.taskDeletions.listen(_onTaskDeleted);
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _projectDeleteSubscription?.cancel();
    _taskDeleteSubscription?.cancel();
    super.dispose();
  }

  void _onProjectUpdated(Project updatedProject) {
    if (!mounted) return;
    setState(() {
      final index = _projects.indexWhere((p) => p.id == updatedProject.id);
      if (index != -1) {
        if (updatedProject.status != 'ACTIVE') {
          // Проект архивирован — убираем из сайдбара как при удалении
          _projects.removeAt(index);
          if (_selectedProject?.id == updatedProject.id) {
            _selectedProject = null;
            _selectedPageId = 'inbox';
            _currentPageArgs = null;
          }
        } else {
          _projects[index] = updatedProject;
          if (_selectedProject?.id == updatedProject.id) {
            _selectedProject = updatedProject;
          }
        }
      }
    });
  }

  void _onProjectDeleted(String projectId) {
    if (!mounted) return;
    setState(() {
      _projects.removeWhere((p) => p.id == projectId);
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
        _selectedPageId = 'inbox'; // Переключаемся на Inbox
        _currentPageArgs = null;
      }
    });
  }

  void _onTaskDeleted(String taskId) {
    if (!mounted) return;
    setState(() {
      if (_selectedTask?.id == taskId) {
        _selectedTask = null;
      }
    });
  }

  // Метод загрузки проектов
  Future<void> _fetchProjects() async {
    try {
      final projects = await _projectService.getProjects();
      if (mounted) {
        setState(() {
          _projects = projects.where((p) => p.status == 'ACTIVE').toList();
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
        status: updatedTask.status,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  Future<void> _handleProjectUpdate(Project updatedProject) async {
    try {
      setState(() {
        _selectedProject = updatedProject;
      });

      await _projectService.updateProject(
        projectId: updatedProject.id,
        name: updatedProject.name,
        description: updatedProject.description,
        colorId: updatedProject.colorId,
        deadline: updatedProject.deadline,
        type: updatedProject.type,
        status: updatedProject.status,
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
      if (_currentPageArgs is Project) {
        _selectedProject = _currentPageArgs as Project;
      } else {
        _selectedProject = null;
      }
      _selectedTask = null; // Сбрасываем выбранную задачу при смене раздела
    });
    logger.i('Переключение на страницу: $pageId с аргументами: $args');
  }

  // Метод обработки клика по задаче (вызывается из TodayScreen и др)
  void _handleTaskTap(Task task) {
    logger.i('Выбрана задача: ${task.name}');
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
          service: _taskService,
        );

      case 'inbox':
        logger.i('Построение экрана InboxScreen');
        return InboxScreen(
          onTaskTap: _handleTaskTap, // Подключаем тап!
          service: _taskService,
        );

      case 'project':
        logger.i('Построение экрана ProjectDetailsScreen');
        // Достаем проект из аргументов
        if (_currentPageArgs is Project) {
          return ProjectDetailsScreen(
            project: _currentPageArgs as Project,
            onTaskTap: _handleTaskTap, // Подключаем тап!
            service: _taskService,
          );
        }
        return const Center(child: Text("Ошибка: Проект не выбран"));

      default:
        return const Center(child: Text("404"));
    }
  }

  Widget _buildInspectorContent() {
    if (_selectedTask != null) {
      return TaskDetailView(
        task: _selectedTask,
        projects: _projects,
        taskService: _taskService,
        onTaskUpdated: _handleTaskUpdate,
        onDelete: () => _onTaskDeleted(_selectedTask!.id),
        onClose: () => setState(() => _selectedTask = null),
      );
    }
    if (_selectedProject != null) {
      return ProjectDetailsView(
        project: _selectedProject,
        projectService: _projectService,
        taskService: _taskService,
        onDelete: () => _onProjectDeleted(_selectedProject!.id),
        onProjectUpdated: _handleProjectUpdate,
        onClose: () => setState(() => _selectedProject = null),
      );
    }
    return const BasicDetailView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Сайдбар
          _isLoading
              ? const SizedBox.shrink()
              : AppSidebar(
                  projects: _projects,
                  onPageSelected: _onPageChanged,
                  onProjectCreated: (newProject) {
                    setState(() => _projects.add(newProject));
                  },
                  projectService: _projectService,
                  selectedPageId: _selectedPageId,
                  selectedProjectId: _selectedProject?.id,
                  auth: widget.auth,
                ),

          // 2. Основной контент
          Expanded(child: _buildActiveScreen()),

          // 3. Инспектор (всегда присутствует, сворачивается до полоски)
          RightSidebar(
            selectionKey: _selectedTask?.id ?? _selectedProject?.id,
            child: _buildInspectorContent(),
          ),
        ],
      ),
    );
  }
}
