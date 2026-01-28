import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_scren.dart';

@GenerateMocks([TaskService])
import 'project_screen_test.mocks.dart';

void main() {
  late MockTaskService mockTaskService;
  const testProjectId = '5';
  final testProject = Project(
    id: testProjectId,
    name: 'Test Project',
    description: 'A project for testing',
    status: 'ACTIVE',
  );

  setUp(() {
    mockTaskService = MockTaskService();
  });

  testWidgets('ProjectScreen adds task with correct Project ID', (
    tester,
  ) async {
    // 1. Мокаем получение задач проекта
    when(
      mockTaskService.getTasksByProject(projectId: testProjectId),
    ).thenAnswer((_) async => []);

    // 2. Мокаем создание задачи
    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        projectId: anyNamed('projectId'), // Важный параметр
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

    // 3. Рендерим (ProjectScreen должен быть обновлен для приема service)
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectDetailsScreen(
          project: testProject,
          service: mockTaskService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Действие пользователя
    await tester.enterText(find.byType(TextField), 'Задача в проект');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // 5. Проверка
    verify(
      mockTaskService.createTask(
        taskName: 'Задача в проект',
        projectId:
            testProjectId, // <--- Убеждаемся, что ID проекта улетел на бэкенд
      ),
    ).called(1);
  });
}
