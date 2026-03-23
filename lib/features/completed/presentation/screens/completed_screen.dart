import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_item.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';

class CompletedScreen extends StatefulWidget {
  final Function(Task)? onTaskTap;
  final Function(Project)? onProjectTap;
  final TaskService? taskService;
  final ProjectService? projectService;

  const CompletedScreen({
    super.key,
    this.onTaskTap,
    this.onProjectTap,
    this.taskService,
    this.projectService,
  });

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Expanded(
          child: IndexedStack(
            index: _activeTab,
            children: [
              _CompletedTasksTab(
                taskService: widget.taskService,
                onTaskTap: widget.onTaskTap,
              ),
              _CompletedProjectsTab(
                projectService: widget.projectService,
                onProjectTap: widget.onProjectTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 17, 22, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Выполненное', style: AppTextStyles.screenTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              _TabButton(
                label: 'Задачи',
                isActive: _activeTab == 0,
                onTap: () => setState(() => _activeTab = 0),
              ),
              const SizedBox(width: 4),
              _TabButton(
                label: 'Проекты',
                isActive: _activeTab == 1,
                onTap: () => setState(() => _activeTab = 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Таба: Задачи ─────────────────────────────────────────────────────────────

class _CompletedTasksTab extends StatefulWidget {
  final TaskService? taskService;
  final Function(Task)? onTaskTap;

  const _CompletedTasksTab({this.taskService, this.onTaskTap});

  @override
  State<_CompletedTasksTab> createState() => _CompletedTasksTabState();
}

class _CompletedTasksTabState extends State<_CompletedTasksTab> {
  late final TaskService _taskService;
  final List<Task> _tasks = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _taskService = widget.taskService ?? getIt<TaskService>();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final newTasks = await _taskService.getCompletedTasks(
        offset: _tasks.length.toString(),
        limit: _pageSize.toString(),
      );
      if (mounted) {
        setState(() {
          _tasks.addAll(newTasks);
          _hasMore = newTasks.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _tasks.isEmpty) {
      return const _EmptyState(message: 'Ещё нет выполненных задач');
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      itemCount: _tasks.length + 1,
      itemBuilder: (context, index) {
        if (index == _tasks.length) {
          if (_isLoading) {
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
          if (!_hasMore && _tasks.isNotEmpty) {
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
          onStatusChanged: (_) {},
          onTap: widget.onTaskTap != null ? () => widget.onTaskTap!(task) : null,
        );
      },
    );
  }
}

// ─── Таба: Проекты ────────────────────────────────────────────────────────────

class _CompletedProjectsTab extends StatefulWidget {
  final ProjectService? projectService;
  final Function(Project)? onProjectTap;

  const _CompletedProjectsTab({this.projectService, this.onProjectTap});

  @override
  State<_CompletedProjectsTab> createState() => _CompletedProjectsTabState();
}

class _CompletedProjectsTabState extends State<_CompletedProjectsTab> {
  late final ProjectService _projectService;
  final List<Project> _projects = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? getIt<ProjectService>();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final newProjects = await _projectService.getCompletedProjects(
        offset: _projects.length.toString(),
        limit: _pageSize.toString(),
      );
      if (mounted) {
        setState(() {
          _projects.addAll(newProjects);
          _hasMore = newProjects.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _projects.isEmpty) {
      return const _EmptyState(message: 'Ещё нет выполненных проектов');
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      itemCount: _projects.length + 1,
      itemBuilder: (context, index) {
        if (index == _projects.length) {
          if (_isLoading) {
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
          if (!_hasMore && _projects.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Все проекты загружены',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        final project = _projects[index];
        return _CompletedProjectItem(
          project: project,
          onTap: widget.onProjectTap != null
              ? () => widget.onProjectTap!(project)
              : null,
        );
      },
    );
  }
}

// ─── Карточка завершённого проекта ────────────────────────────────────────────

class _CompletedProjectItem extends StatefulWidget {
  final Project project;
  final VoidCallback? onTap;

  const _CompletedProjectItem({required this.project, this.onTap});

  @override
  State<_CompletedProjectItem> createState() => _CompletedProjectItemState();
}

class _CompletedProjectItemState extends State<_CompletedProjectItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorIndex = int.tryParse(widget.project.colorId ?? '0') ?? 0;
    final dotColor = ProjectColorData.getColor(context, colorIndex);
    final dateStr = widget.project.updatedAt != null
        ? DateFormat('d MMM yyyy').format(widget.project.updatedAt!)
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.bgPanel : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? AppColors.borderLight : Colors.transparent,
            ),
            boxShadow: _isHovered
                ? const [
                    BoxShadow(
                      color: Color(0x172A1F14),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      style: AppTextStyles.taskTitle.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                    if (dateStr != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Завершён $dateStr',
                        style: AppTextStyles.metaText,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 36,
              color: AppColors.borderLight,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Кнопка таба ──────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyText.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
