import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/basic_detail_view.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/widgets/project_details_view.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/right_sidebar.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_detail_view.dart';

@GenerateMocks([TaskService, ProjectService])
import 'right_sidebar_test.mocks.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    final mockTaskService = MockTaskService();
    final mockProjectService = MockProjectService();
    when(mockTaskService.taskUpdates).thenAnswer((_) => const Stream.empty());
    when(mockTaskService.taskDeletions).thenAnswer((_) => const Stream.empty());
    when(
      mockProjectService.projectUpdates,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockProjectService.projectDeletions,
    ).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<TaskService>(mockTaskService);
    getIt.registerSingleton<ProjectService>(mockProjectService);
  });

  tearDown(() {
    getIt.reset();
  });

  group('RightSidebar Tests', () {
    final testTask = Task(
      id: '1',
      name: 'Test Task Name',
      description: 'Test Task Description',
      status: 'TODO',
      projectId: '1',
    );

    final testProject = Project(
      id: '1',
      name: 'Test Project Name',
      description: 'Test Project Description',
      status: 'ACTIVE',
      colorId: '1',
    );

    testWidgets('should render TaskDetailView when selectedTask is provided', (
      tester,
    ) async {
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightSidebar(
              selectedTask: testTask,
              selectedProject: null,
              onTaskUpdate: (_) async {},
              onProjectUpdate: (_) async {},
              allProjects: [],
              onClose: () {},
              onTaskDelete: () {},
              onProjectDelete: () {},
            ),
          ),
        ),
      );

      // ASSERT
      expect(find.byType(TaskDetailView), findsOneWidget);
      expect(find.byType(ProjectDetailsView), findsNothing);
      expect(find.byType(BasicDetailView), findsNothing);
    });

    testWidgets(
      'should render ProjectDetailsView when selectedProject is provided',
      (tester) async {
        // ARRANGE
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RightSidebar(
                selectedTask: null,
                selectedProject: testProject,
                onTaskUpdate: (_) async {},
                onProjectUpdate: (_) async {},
                allProjects: [],
                onClose: () {},
                onTaskDelete: () {},
                onProjectDelete: () {},
              ),
            ),
          ),
        );

        // ASSERT
        expect(find.byType(ProjectDetailsView), findsOneWidget);
        expect(find.byType(TaskDetailView), findsNothing);
        expect(find.byType(BasicDetailView), findsNothing);
      },
    );

    testWidgets('should render BasicDetailView when nothing is selected', (
      tester,
    ) async {
      // ARRANGE
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightSidebar(
              selectedTask: null,
              selectedProject: null,
              onTaskUpdate: (_) async {},
              onProjectUpdate: (_) async {},
              allProjects: [],
              onClose: () {},
              onTaskDelete: () {},
              onProjectDelete: () {},
            ),
          ),
        ),
      );

      // ASSERT
      expect(find.byType(BasicDetailView), findsOneWidget);
      expect(find.byType(TaskDetailView), findsNothing);
      expect(find.byType(ProjectDetailsView), findsNothing);
    });

    testWidgets('should call onClose when close button is tapped', (
      tester,
    ) async {
      // ARRANGE
      bool isClosed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightSidebar(
              selectedTask: null,
              selectedProject: null,
              onClose: () {
                isClosed = true;
              },
              onTaskDelete: () {},
              onProjectDelete: () {},
            ),
          ),
        ),
      );

      // ACT
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);

      // ASSERT
      expect(isClosed, isTrue);
    });
  });
}
