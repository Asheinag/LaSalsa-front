import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_detail_view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:intl/intl.dart';

import 'task_inspector_test.mocks.dart';

@GenerateMocks([TaskService])
void main() {
  late MockTaskService mockTaskService;

  setUp(() {
    mockTaskService = MockTaskService();
  });

  group('TaskDetailView', () {
    testWidgets(
      'should display "select a task" message when no task is provided',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TaskDetailView(taskService: mockTaskService)),
          ),
        );

        // Assert
        expect(
          find.text('Выберите задачу,\nчтобы увидеть детали'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.touch_app_outlined), findsOneWidget);
      },
    );

    testWidgets('should display task details when a task is provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Initial Description',
        status: 'TODO',
        projectId: 'p-1',
      );

      final detailedTask = Task(
        id: '1',
        name: 'Test Task',
        description: 'Detailed Description',
        status: 'TODO',
        projectId: 'p-1',
      );

      final project = Project(
        id: 'p-1',
        name: 'Test Project',
        status: 'ACTIVE',
        colorId: '1',
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => detailedTask);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              projects: [project],
              taskService: mockTaskService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Task'), findsOneWidget);
      // The description is updated asynchronously
      expect(find.text('Detailed Description'), findsOneWidget);
      expect(find.text('Test Project'), findsOneWidget);
    });
  });

  group('Interactions', () {
    testWidgets('should call onTaskUpdated when name is changed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        projectId: 'p-1',
      );
      final project = Project(
        id: 'p-1',
        name: 'Test Project',
        status: 'ACTIVE',
        colorId: '1',
      );
      Task? updatedTask;

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              projects: [project],
              taskService: mockTaskService,
              onTaskUpdated: (task) async {
                updatedTask = task;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(
        find.widgetWithText(TextField, 'Test Task'),
        'New Task Name',
      );
      await tester.pump(const Duration(seconds: 3));

      // Assert
      expect(updatedTask, isNotNull);
      expect(updatedTask?.name, 'New Task Name');
    });

    testWidgets('should call onTaskUpdated when description is changed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        projectId: 'p-1',
      );
      final project = Project(
        id: 'p-1',
        name: 'Test Project',
        status: 'ACTIVE',
        colorId: '1',
      );
      Task? updatedTask;

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              projects: [project],
              taskService: mockTaskService,
              onTaskUpdated: (task) async {
                updatedTask = task;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(
        find.widgetWithText(TextField, 'Test Description'),
        'New Description',
      );
      await tester.pump(const Duration(seconds: 3));

      // Assert
      expect(updatedTask, isNotNull);
      expect(updatedTask?.description, 'New Description');
    });

    testWidgets('should call onTaskUpdated when project is changed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        projectId: 'p-1',
      );
      final project1 = Project(
        id: 'p-1',
        name: 'Test Project 1',
        status: 'ACTIVE',
        colorId: '1',
      );
      final project2 = Project(
        id: 'p-2',
        name: 'Test Project 2',
        status: 'ACTIVE',
        colorId: '2',
      );
      Task? updatedTask;

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              projects: [project1, project2],
              taskService: mockTaskService,
              onTaskUpdated: (task) async {
                updatedTask = task;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Test Project 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project 2').last);
      await tester.pumpAndSettle();

      // Assert
      expect(updatedTask, isNotNull);
      expect(updatedTask?.projectId, 'p-2');
    });

    testWidgets('should call onDelete when delete button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
      );
      bool onDeleteCalled = false;

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);
      when(mockTaskService.deleteTask(taskId: '1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              taskService: mockTaskService,
              onDelete: () {
                onDeleteCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Assert
      verify(mockTaskService.deleteTask(taskId: '1')).called(1);
      expect(onDeleteCalled, isTrue);
    });

    testWidgets('should call onClose when close button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
      );
      bool onCloseCalled = false;

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              taskService: mockTaskService,
              onClose: () {
                onCloseCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert
      expect(onCloseCalled, isTrue);
    });

    testWidgets('should display saving indicator during update', (
      WidgetTester tester,
    ) async {
      // Arrange
      final completer = Completer<void>();
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        projectId: 'p-1',
      );
      final project1 = Project(
        id: 'p-1',
        name: 'Project 1',
        status: 'ACTIVE',
        colorId: '1',
      );
      final project2 = Project(
        id: 'p-2',
        name: 'Project 2',
        status: 'ACTIVE',
        colorId: '2',
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              projects: [project1, project2],
              taskService: mockTaskService,
              onTaskUpdated: (_) => completer.future,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Project 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project 2').last);
      await tester.pump(); // Start the update process

      // Assert: Indicator is visible
      expect(find.text('Сохранение...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up
      completer.complete();
      await tester.pumpAndSettle();

      // Assert: Indicator is gone
      expect(find.text('Сохранение...'), findsNothing);
    });
  });

  group('Date Display', () {
    testWidgets('should display future date with correct style', (
      WidgetTester tester,
    ) async {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        plannedAt: futureDate,
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final dateText = tester.widget<Text>(
        find.text(DateFormat('dd MMM yyyy').format(futureDate)),
      );
      expect(dateText.style?.color, equals(Colors.blueGrey[800]));
    });

    testWidgets('should display overdue date with correct style', (
      WidgetTester tester,
    ) async {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        plannedAt: pastDate,
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final dateText = tester.widget<Text>(
        find.text(DateFormat('dd MMM yyyy').format(pastDate)),
      );
      expect(dateText.style?.color, equals(Colors.deepOrange[700]));
    });

    testWidgets('should display placeholder when date is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
        plannedAt: null,
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final placeholderText = tester.widget<Text>(
        find.text('Добавить плановую дату завершения'),
      );
      expect(placeholderText.style?.color, equals(Colors.grey));
    });

    testWidgets('should display closed date when task is closed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final closedDate = DateTime.now().subtract(const Duration(days: 2));
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'DONE',
        closedAt: closedDate,
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Завершено'), findsOneWidget);
      expect(
        find.text(DateFormat('dd MMM yyyy, HH:mm').format(closedDate)),
        findsOneWidget,
      );
    });
  });

  group('State & Edge Cases', () {
    testWidgets('should update controllers and fetch details on task change', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task1 = Task(
        id: '1',
        name: 'Task 1',
        description: 'Description 1',
        status: 'TODO',
      );
      final task2 = Task(
        id: '2',
        name: 'Task 2',
        description: 'Description 2',
        status: 'TODO',
      );

      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task1);
      when(
        mockTaskService.getTaskDetails(taskId: '2'),
      ).thenAnswer((_) async => task2);

      // Initial build with Task 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task1, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Description 1'), findsOneWidget);
      verify(mockTaskService.getTaskDetails(taskId: '1')).called(1);

      // Act: Rebuild with Task 2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task2, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Description 2'), findsOneWidget);
      verify(mockTaskService.getTaskDetails(taskId: '2')).called(1);
    });

    testWidgets('should show snackbar on getTaskDetails error', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
      );
      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenThrow(Exception('Failed to load'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(task: task, taskService: mockTaskService),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Ошибка загрузки задачи: Exception: Failed to load'),
        findsOneWidget,
      );
    });

    testWidgets('should show snackbar on deleteTask error', (
      WidgetTester tester,
    ) async {
      // Arrange
      final task = Task(
        id: '1',
        name: 'Test Task',
        description: 'Test Description',
        status: 'TODO',
      );
      when(
        mockTaskService.getTaskDetails(taskId: '1'),
      ).thenAnswer((_) async => task);
      when(
        mockTaskService.deleteTask(taskId: '1'),
      ).thenThrow(Exception('Failed to delete'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDetailView(
              task: task,
              taskService: mockTaskService,
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Ошибка удаления задачи: Exception: Failed to delete'),
        findsOneWidget,
      );
    });

    testWidgets(
      'should not show close and delete buttons if callbacks are null',
      (WidgetTester tester) async {
        // Arrange
        final task = Task(
          id: '1',
          name: 'Test Task',
          description: 'Test Description',
          status: 'TODO',
        );
        when(
          mockTaskService.getTaskDetails(taskId: '1'),
        ).thenAnswer((_) async => task);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskDetailView(
                task: task,
                taskService: mockTaskService,
                onDelete: null,
                onClose: null,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.delete), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );
  });
}
