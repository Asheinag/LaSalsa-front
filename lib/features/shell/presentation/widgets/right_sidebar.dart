import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/widgets/project_details_view.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_detail_view.dart';
import 'package:kabachok_lasalsa_front/core/widgets/basic_detail_view.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
// Дебаг
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class RightSidebar extends StatelessWidget {
  final Task? selectedTask;
  final Project? selectedProject;
  final bool showBasicDetailView;

  final Future<void> Function(Task)? onTaskUpdate;
  final Future<void> Function(Project)? onProjectUpdate;

  final List<Project> allProjects;

  final VoidCallback onClose;
  final VoidCallback onTaskDelete;
  final VoidCallback onProjectDelete;

  const RightSidebar({
    super.key,
    this.selectedTask,
    this.selectedProject,
    this.showBasicDetailView = false,
    this.onTaskUpdate,
    this.onProjectUpdate,
    required this.onClose,
    required this.onTaskDelete,
    required this.onProjectDelete,
    this.allProjects = const [],
  });

  @override
  Widget build(BuildContext context) {
    logger.i('selected task is $selectedTask');
    logger.i('All projects - ${allProjects.length}');
    Widget content;
    if (selectedTask != null) {
      logger.i('SHOW TASK DETAIL VIEW');
      content = TaskDetailView(
        task: selectedTask,
        projects: allProjects,
        onTaskUpdated: onTaskUpdate,
        onDelete: onTaskDelete,
      );
    } else if (selectedProject != null) {
      logger.i('SHOW PROJECT DETAIL VIEW');
      content = ProjectDetailsView(
        project: selectedProject,
        onDelete: onProjectDelete,
        onProjectUpdated: onProjectUpdate,
      );
    } else {
      content = BasicDetailView();
    }

    return Container(
      width: 550,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ),
          const Divider(height: 1),

          // КОНКРЕТНЫЙ КОНТЕНТ
          Expanded(child: content),
        ],
      ),
    );
  }
}
