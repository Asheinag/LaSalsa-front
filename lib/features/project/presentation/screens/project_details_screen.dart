import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final Project project;
  final TaskService taskService;
  final ProjectService projectService;
  final Function(Task)? onTaskTap;

  ProjectDetailsScreen({
    super.key,
    required this.project,
    TaskService? service,
    ProjectService? projectSvc,
    this.onTaskTap,
  })  : taskService = service ?? TaskService(),
        projectService = projectSvc ?? getIt<ProjectService>();

  @override
  Widget build(BuildContext context) {
    logger.i('Открыт проект: ${project.name} (ID: ${project.id})');
    return TaskListView(
      key: ValueKey(project.id),
      title: project.name,
      fetcher: (offset, limit) => projectService.getActiveProjectTasks(
        projectId: project.id,
        offset: '$offset',
        limit: '$limit',
      ),
      creator: (title, plannedAt) => taskService.createTask(
        projectId: project.id,
        taskName: title,
        plannedAt: plannedAt,
      ),
      emptyListMessage: 'В этом проекте нет активных задач',
      onTaskTap: onTaskTap,
      service: taskService,
      removeIf: (task) => task.projectId != project.id,
    );
  }
}
