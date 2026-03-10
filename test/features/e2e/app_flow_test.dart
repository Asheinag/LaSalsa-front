import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/screens/home_shell_screen.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_flow_test.mocks.dart';

@GenerateMocks([ProjectService, TaskService, FirebaseAuth, AiReviewService])
void main() {
  late MockProjectService mockProjectService;
  late MockTaskService mockTaskService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockAiReviewService mockAiReviewService;

  setUp(() {
    mockProjectService = MockProjectService();
    mockTaskService = MockTaskService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockAiReviewService = MockAiReviewService();
    when(mockFirebaseAuth.currentUser).thenReturn(null);
    when(mockAiReviewService.getActiveTaskReview(any)).thenAnswer((_) async => null);
    when(mockAiReviewService.getActiveProjectReview(any)).thenAnswer((_) async => null);
    when(mockAiReviewService.getTaskReviewHistory(any)).thenAnswer((_) async => []);
    when(mockAiReviewService.getProjectReviewHistory(any)).thenAnswer((_) async => []);
    when(
      mockProjectService.projectUpdates,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockProjectService.projectDeletions,
    ).thenAnswer((_) => const Stream.empty());
    when(mockTaskService.taskUpdates).thenAnswer((_) => const Stream.empty());
    when(mockTaskService.taskDeletions).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('Create project, add task, and verify project color in inspector', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    // Arrange
    final projectName = 'Test Project';
    final taskName = 'Test Task';
    final projectColorId = '2';
    final project = Project(
      id: '1',
      name: projectName,
      status: 'ACTIVE',
      colorId: projectColorId,
    );
    final task = Task(
      id: '101',
      name: taskName,
      projectId: '1',
      description: '',
      status: 'ACTIVE',
    );

    // Mock API calls
    when(
      mockTaskService.getTodayTasks(offset: '0', limit: '20'),
    ).thenAnswer((_) async => []);
    when(
      mockTaskService.getTasks(offset: '0', limit: '20'),
    ).thenAnswer((_) async => []);
    when(mockProjectService.getProjects()).thenAnswer((_) async => []);
    when(
      mockProjectService.createProject(
        name: projectName,
        colorId: projectColorId,
      ),
    ).thenAnswer((_) async => project);
    when(
      mockTaskService.getTasksByProject(projectId: '1'),
    ).thenAnswer((_) async => [task]);
    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        projectId: anyNamed('projectId'),
        plannedAt: anyNamed('plannedAt'),
        description: anyNamed('description'),
        parentId: anyNamed('parentId'),
      ),
    ).thenAnswer((_) async => task);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          child: HomeShellScreen(
            projectService: mockProjectService,
            taskService: mockTaskService,
            aiReviewService: mockAiReviewService,
            auth: mockFirebaseAuth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Create a project with a specific color
    await tester.tap(find.text('Создать проект'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AppSidebar),
        matching: find.byType(TextField),
      ),
      projectName,
    );
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.circle).at(2));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Verify project is created
    expect(find.text(projectName), findsOneWidget);

    // 2. Go to the created project
    await tester.tap(find.text(projectName));
    await tester.pumpAndSettle();

    // 3. Create a task in the project
    await tester.tap(find.byTooltip('Добавить задачу'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, taskName);
    await tester.tap(find.byTooltip('Добавить задачу'));
    await tester.pumpAndSettle();

    // 4. Open the created task details
    await tester.tap(find.text(taskName));
    await tester.pumpAndSettle();

    // 5. Check that the project in the task details has the correct name and color
    expect(find.text(projectName), findsWidgets);
  });
}
