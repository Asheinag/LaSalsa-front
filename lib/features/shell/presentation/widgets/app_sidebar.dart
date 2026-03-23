import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart' as di;

class AppSidebar extends StatefulWidget {
  final List<Project> projects;
  final Function(String pageId, {dynamic args}) onPageSelected;
  final Function(Project newProject)? onProjectCreated;
  final ProjectService? projectService;
  final String selectedPageId;
  final String? selectedProjectId;
  final FirebaseAuth? auth;

  const AppSidebar({
    super.key,
    required this.onPageSelected,
    required this.projects,
    this.onProjectCreated,
    this.projectService,
    this.selectedPageId = 'today',
    this.selectedProjectId,
    this.auth,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late final ProjectService _projectService;
  bool _isCollapsed = false;
  bool _isCreatingProject = false;
  final _newProjectController = TextEditingController();
  int _selectedColorId = 0;

  static const double _expandedWidth = 216;
  static const double _collapsedWidth = 52;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? ProjectService();
  }

  @override
  void dispose() {
    _newProjectController.dispose();
    super.dispose();
  }

  Future<void> _submitNewProject() async {
    final name = _newProjectController.text.trim();
    if (name.isEmpty) {
      setState(() => _isCreatingProject = false);
      _newProjectController.clear();
      return;
    }
    try {
      final newProject = await _projectService.createProject(
        name: name,
        colorId: _selectedColorId.toString(),
      );
      if (mounted) {
        setState(() => _isCreatingProject = false);
        widget.onProjectCreated?.call(
          newProject.copyWith(colorId: _selectedColorId.toString()),
        );
      }
    } catch (e) {
      logger.e('Не удалось создать проект: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания проекта')),
        );
        setState(() => _isCreatingProject = false);
      }
    }
    _newProjectController.clear();
  }

  Future<void> _handleLogout() async {
    try {
      await di.reset();
      await (widget.auth ?? FirebaseAuth.instance).signOut();
    } catch (e) {
      logger.e('Ошибка при выходе: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: $e')),
        );
      }
    }
  }

  String _getInitials(String nameOrEmail) {
    final parts =
        nameOrEmail.split(RegExp(r'[@.\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.ease,
        width: _isCollapsed ? _collapsedWidth : _expandedWidth,
        decoration: const BoxDecoration(
          color: AppColors.bgSidebar,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _buildSectionLabel('Обзор'),
                    _SidebarNavItem(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Сегодня',
                      isActive: widget.selectedPageId == 'today',
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onPageSelected('today'),
                    ),
                    _SidebarNavItem(
                      icon: Icons.inbox_outlined,
                      label: 'Входящие',
                      isActive: widget.selectedPageId == 'inbox',
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onPageSelected('inbox'),
                    ),
                    _SidebarNavItem(
                      icon: Icons.check_circle_outline,
                      label: 'Выполненное',
                      isActive: widget.selectedPageId == 'completed',
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onPageSelected('completed'),
                    ),
                    const SizedBox(height: 14),
                    _buildSectionLabel('Проекты'),
                    ...widget.projects.map(_buildProjectItem),
                    if (!_isCollapsed) _buildCreateProjectButton(),
                    if (_isCreatingProject && !_isCollapsed) _buildNewProjectForm(),
                    const SizedBox(height: 14),
                    _buildSectionLabel('Планирование'),
                    _SidebarNavItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Неделя',
                      isActive: false,
                      isCollapsed: _isCollapsed,
                      disabled: true,
                      onTap: null,
                    ),
                    _SidebarNavItem(
                      icon: Icons.timer_outlined,
                      label: 'Pomodoro',
                      isActive: false,
                      isCollapsed: _isCollapsed,
                      disabled: true,
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 12 : 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          const Text('🌶️', style: TextStyle(fontSize: 20)),
          Flexible(
            child: AnimatedOpacity(
              opacity: _isCollapsed ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'LaSalsa',
                  style: GoogleFonts.lora(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    if (_isCollapsed) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      child: Text(label.toUpperCase(), style: AppTextStyles.sidebarLabel),
    );
  }

  Widget _buildProjectItem(Project project) {
    final colorIndex = int.tryParse(project.colorId ?? '0') ?? 0;
    final dotColor = ProjectColorData.getColor(context, colorIndex);
    final isActive = widget.selectedPageId == 'project' &&
        widget.selectedProjectId == project.id;
    return _SidebarNavItem(
      label: project.name,
      isActive: isActive,
      isCollapsed: _isCollapsed,
      onTap: () => widget.onPageSelected('project', args: project),
      dotColor: dotColor,
    );
  }

  Widget _buildCreateProjectButton() {
    return _SidebarNavItem(
      icon: Icons.add,
      label: 'Создать проект',
      isActive: false,
      isCollapsed: false,
      muted: true,
      onTap: () => setState(() {
        _isCreatingProject = !_isCreatingProject;
        _selectedColorId = 0;
      }),
    );
  }

  Widget _buildNewProjectForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          DropdownButton<int>(
            value: _selectedColorId,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedColorId = v);
            },
            items: List.generate(
              ProjectColorData.palette.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Icon(
                  Icons.circle,
                  color: ProjectColorData.getColor(context, i),
                  size: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _newProjectController,
              autofocus: true,
              style: AppTextStyles.bodyText,
              decoration: const InputDecoration(
                hintText: 'Название проекта',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: (_) => _submitNewProject(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final user = (widget.auth ?? FirebaseAuth.instance).currentUser;
    final initials = _getInitials(user?.email ?? user?.displayName ?? '?');

    final collapseButton = GestureDetector(
      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.bgPanel,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x172A1F14),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedRotation(
          turns: _isCollapsed ? 0.5 : 0,
          duration: const Duration(milliseconds: 220),
          child: const Icon(
            Icons.chevron_left,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: _isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isCollapsed)
            Tooltip(
              message: 'Выйти (${user?.email ?? ''})',
              child: GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.metaText.copyWith(
                      color: AppColors.bgPanel,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          collapseButton,
        ],
      ),
    );
  }
}

// ─── Приватный виджет элемента навигации ─────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  final IconData? icon;
  final Color? dotColor;
  final String label;
  final bool isActive;
  final bool isCollapsed;
  final bool disabled;
  final bool muted;
  final VoidCallback? onTap;

  const _SidebarNavItem({
    required this.label,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
    this.icon,
    this.dotColor,
    this.disabled = false,
    this.muted = false,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (widget.isActive) {
      bg = AppColors.bgActive;
    } else if (_isHovered && widget.onTap != null) {
      bg = AppColors.bgHover;
    } else {
      bg = Colors.transparent;
    }

    final Color textColor;
    if (widget.disabled || widget.muted) {
      textColor = AppColors.textMuted;
    } else if (widget.isActive) {
      textColor = AppColors.textPrimary;
    } else {
      textColor = AppColors.textSecondary;
    }

    Widget leading;
    if (widget.dotColor != null) {
      leading = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.dotColor,
          shape: BoxShape.circle,
        ),
      );
    } else if (widget.icon != null) {
      leading = Opacity(
        opacity: widget.disabled ? 0.35 : (widget.isActive ? 1.0 : 0.75),
        child: Icon(
          widget.icon!,
          size: 18,
          color: widget.isActive ? AppColors.accent : AppColors.textSecondary,
        ),
      );
    } else {
      leading = const SizedBox(width: 8, height: 8);
    }

    Widget item = Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            SizedBox(width: 18, child: Center(child: leading)),
            Flexible(
              child: AnimatedOpacity(
                opacity: widget.isCollapsed ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.label,
                    style: AppTextStyles.taskTitle.copyWith(
                      color: textColor,
                      fontWeight: widget.isActive
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isCollapsed) {
      item = Tooltip(message: widget.label, child: item);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(onTap: widget.onTap, child: item),
    );
  }
}
