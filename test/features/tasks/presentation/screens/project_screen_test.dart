import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_screen.dart';

@GenerateMocks([TaskService, ProjectService])
import 'project_screen_test.mocks.dart';

void main() {
  late MockTaskService mockTaskService;
  late MockProjectService mockProjectService;
  const testProjectId = '5';
  final testProject = Project(
    id: testProjectId,
    name: 'Test Project',
    description: 'A project for testing',
    status: 'ACTIVE',
  );

  setUp(() {
    mockTaskService = MockTaskService();
    mockProjectService = MockProjectService();
    when(mockTaskService.taskUpdates).thenAnswer((_) => Stream.empty());
    when(mockTaskService.taskDeletions).thenAnswer((_) => Stream.empty());
    when(mockProjectService.projectUpdates).thenAnswer((_) => Stream.empty());
    when(mockProjectService.projectDeletions).thenAnswer((_) => Stream.empty());
    when(
      mockProjectService.getActiveProjectTasks(
        projectId: anyNamed('projectId'),
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => []);
  });

  testWidgets('ProjectScreen adds task with correct Project ID', (
    tester,
  ) async {
    // 2. Мокаем создание задачи
    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        projectId: anyNamed('projectId'), // Важный параметр
        plannedAt: anyNamed('plannedAt'),
      ),
    ).thenAnswer(
      (_) async => Task(
        id: '1',
        name: 'Task',
        description: '',
        status: 'TODO',
        projectId: testProjectId,
      ),
    );

    // 3. Рендерим
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDetailsScreen(
          project: testProject,
          service: mockTaskService,
          projectSvc: mockProjectService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Действие пользователя
    await tester.enterText(find.byType(TextField), 'Задача в проект');
    await tester.tap(find.byTooltip('Добавить задачу'));
    await tester.pumpAndSettle();

    // 5. Проверка
    verify(
      mockTaskService.createTask(
        taskName: 'Задача в проект',
        projectId:
            testProjectId, // <--- Убеждаемся, что ID проекта улетел на бэкенд
        plannedAt: null,
      ),
    ).called(1);
  });

  testWidgets('ProjectDetailsScreen should display tasks on successful fetch', (
    tester,
  ) async {
    // ARRANGE
    final fakeTasks = [
      Task(
        id: '1',
        name: 'Project Task 1',
        description: '',
        status: 'TODO',
        projectId: testProjectId,
      ),
      Task(
        id: '2',
        name: 'Project Task 2',
        description: '',
        status: 'TODO',
        projectId: testProjectId,
      ),
    ];

    when(
      mockProjectService.getActiveProjectTasks(
        projectId: testProjectId,
        offset: '0',
        limit: '30',
      ),
    ).thenAnswer((_) async => fakeTasks);

    // Mock the creator as well
    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        projectId: anyNamed('projectId'),
        plannedAt: anyNamed('plannedAt'),
      ),
    ).thenAnswer(
      (_) async => Task(
        id: '3',
        name: 'New',
        description: '',
        status: 'TODO',
        projectId: testProjectId,
      ),
    );

    // ACT
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDetailsScreen(
          project: testProject,
          service: mockTaskService,
          projectSvc: mockProjectService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Project Task 1'), findsOneWidget);
    expect(find.text('Project Task 2'), findsOneWidget);
  });
}
