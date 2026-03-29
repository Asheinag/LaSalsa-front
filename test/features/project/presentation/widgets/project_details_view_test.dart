import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/project_stats.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/widgets/project_details_view.dart';

@GenerateMocks([ProjectService, TaskService, AiReviewService])
import 'project_details_view_test.mocks.dart';

void main() {
  late MockProjectService mockProjectService;
  late MockTaskService mockTaskService;
  late MockAiReviewService mockAiReviewService;
  late StreamController<Task> taskUpdateController;
  late StreamController<String> taskDeleteController;

  const projectId = 'proj-1';
  final project = Project(
    id: projectId,
    name: 'Тестовый проект',
    status: 'ACTIVE',
    colorId: '0',
  );

  final todoTask = Task(
    id: 't1',
    name: 'Активная задача',
    description: '',
    status: 'TODO',
    projectId: projectId,
  );
  final doneTask = Task(
    id: 't2',
    name: 'Выполненная задача',
    description: '',
    status: 'DONE',
    projectId: projectId,
  );

  setUp(() {
    mockProjectService = MockProjectService();
    mockTaskService = MockTaskService();
    mockAiReviewService = MockAiReviewService();
    taskUpdateController = StreamController<Task>.broadcast();
    taskDeleteController = StreamController<String>.broadcast();

    when(mockTaskService.taskUpdates)
        .thenAnswer((_) => taskUpdateController.stream);
    when(mockTaskService.taskDeletions)
        .thenAnswer((_) => taskDeleteController.stream);
    when(mockProjectService.projectUpdates)
        .thenAnswer((_) => const Stream.empty());
    when(mockProjectService.projectDeletions)
        .thenAnswer((_) => const Stream.empty());
    when(mockAiReviewService.getActiveProjectReview(any))
        .thenAnswer((_) async => null);
    when(mockProjectService.getProjectStats(projectId: anyNamed('projectId')))
        .thenAnswer((_) async => const ProjectStats(total: 2, active: 1, completed: 1));
    when(mockTaskService.getTasksByProject(projectId: anyNamed('projectId')))
        .thenAnswer((_) async => [todoTask, doneTask]);
  });

  tearDown(() {
    taskUpdateController.close();
    taskDeleteController.close();
  });

  Widget buildWidget() => MaterialApp(
        home: Scaffold(
          body: ProjectDetailsView(
            project: project,
            projectService: mockProjectService,
            taskService: mockTaskService,
            aiReviewService: mockAiReviewService,
          ),
        ),
      );

  group('Статистика проекта — автообновление', () {
    testWidgets('отображает начальную статистику после загрузки', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // "1 активных · 1 выполнено · 2 всего"
      expect(find.textContaining('1 активных'), findsOneWidget);
      expect(find.textContaining('1 выполнено'), findsOneWidget);
      expect(find.textContaining('2 всего'), findsOneWidget);
    });

    testWidgets(
      'при смене статуса TODO→DONE: активных↓, выполнено↑ без запроса к бэку',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        // Сбрасываем счётчик вызовов после инициализации
        clearInteractions(mockProjectService);

        // Переводим todoTask в DONE через стрим
        taskUpdateController.add(todoTask.copyWith(status: 'DONE'));
        await tester.pumpAndSettle();

        expect(find.textContaining('0 активных'), findsOneWidget);
        expect(find.textContaining('2 выполнено'), findsOneWidget);
        expect(find.textContaining('2 всего'), findsOneWidget);

        // Убеждаемся, что дополнительного запроса статистики не было
        verifyNever(mockProjectService.getProjectStats(
          projectId: anyNamed('projectId'),
        ));
      },
    );

    testWidgets(
      'при смене статуса DONE→TODO: активных↑, выполнено↓',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        taskUpdateController.add(doneTask.copyWith(status: 'TODO'));
        await tester.pumpAndSettle();

        expect(find.textContaining('2 активных'), findsOneWidget);
        expect(find.textContaining('0 выполнено'), findsOneWidget);
        expect(find.textContaining('2 всего'), findsOneWidget);
      },
    );

    testWidgets(
      'при удалении задачи: total↓, счётчики пересчитываются',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        // Удаляем активную задачу
        taskDeleteController.add(todoTask.id);
        await tester.pumpAndSettle();

        expect(find.textContaining('0 активных'), findsOneWidget);
        expect(find.textContaining('1 выполнено'), findsOneWidget);
        expect(find.textContaining('1 всего'), findsOneWidget);
      },
    );

    testWidgets(
      'обновление задачи из другого проекта не меняет статистику',
      (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        // Задача с другим projectId
        taskUpdateController.add(Task(
          id: 'other',
          name: 'Чужая задача',
          description: '',
          status: 'DONE',
          projectId: 'other-project',
        ));
        await tester.pumpAndSettle();

        // Статистика не изменилась
        expect(find.textContaining('1 активных'), findsOneWidget);
        expect(find.textContaining('1 выполнено'), findsOneWidget);
        expect(find.textContaining('2 всего'), findsOneWidget);
      },
    );
  });
}
