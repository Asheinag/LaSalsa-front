import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/screens/home_shell_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';

@GenerateMocks([ProjectService, TaskService, FirebaseAuth])
import 'home_shell_screen_test.mocks.dart';

void main() {
  late MockProjectService mockProjectService;
  late MockTaskService mockTaskService;
  late MockFirebaseAuth mockFirebaseAuth;
  late StreamController<Project> projectUpdateController;
  late StreamController<String> projectDeleteController;
  late StreamController<String> taskDeleteController;

  setUp(() {
    mockProjectService = MockProjectService();
    mockTaskService = MockTaskService();
    mockFirebaseAuth = MockFirebaseAuth();
    when(mockFirebaseAuth.currentUser).thenReturn(null);
    projectUpdateController = StreamController<Project>.broadcast();
    projectDeleteController = StreamController<String>.broadcast();
    taskDeleteController = StreamController<String>.broadcast();

    // Настраиваем стрим обновлений
    when(
      mockProjectService.projectUpdates,
    ).thenAnswer((_) => projectUpdateController.stream);
    when(
      mockProjectService.projectDeletions,
    ).thenAnswer((_) => projectDeleteController.stream);

    when(mockTaskService.taskUpdates).thenAnswer((_) => const Stream.empty());
    when(
      mockTaskService.taskDeletions,
    ).thenAnswer((_) => taskDeleteController.stream);
    // Настраиваем заглушки для методов, вызываемых при инициализации
    when(mockProjectService.getProjects()).thenAnswer((_) async => []);
    when(
      mockTaskService.getTodayTasks(
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    projectUpdateController.close();
    projectDeleteController.close();
    taskDeleteController.close();
  });

  testWidgets(
    'HomeShellScreen updates project list when projectUpdates emits event',
    (tester) async {
      // ARRANGE
      final initialProject = Project(
        id: '1',
        name: 'Old Name',
        colorId: '1',
        status: 'ACTIVE',
      );
      final updatedProject = Project(
        id: '1',
        name: 'New Name',
        colorId: '1',
        status: 'ACTIVE',
      );

      // Сначала возвращаем список с "старым" проектом
      when(
        mockProjectService.getProjects(),
      ).thenAnswer((_) async => [initialProject]);

      // ACT
      // Рендерим экран
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShellScreen(
            projectService: mockProjectService,
            taskService: mockTaskService,
            auth: mockFirebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle(); // Ждем завершения загрузки проектов

      // Проверяем, что старое имя отображается (в сайдбаре)
      expect(find.text('Old Name'), findsOneWidget);

      // Эмулируем прилет обновления через стрим (как будто мы отредактировали проект в другом месте)
      projectUpdateController.add(updatedProject);

      await tester.pumpAndSettle(); // Даем UI обновиться

      // ASSERT
      // Проверяем, что имя обновилось на новое
      expect(find.text('New Name'), findsOneWidget);
      expect(find.text('Old Name'), findsNothing);
    },
  );

  testWidgets('HomeShellScreen switches to Inbox when selected project is deleted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    // ARRANGE
    final project = Project(
      id: '1',
      name: 'To Delete',
      colorId: '1',
      status: 'ACTIVE',
    );
    when(mockProjectService.getProjects()).thenAnswer((_) async => [project]);

    // ACT
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellScreen(
          projectService: mockProjectService,
          taskService: mockTaskService,
          auth: mockFirebaseAuth,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Выбираем проект
    await tester.tap(find.text('To Delete'));
    await tester.pumpAndSettle();

    // Эмулируем удаление
    projectDeleteController.add('1');
    await tester.pumpAndSettle();

    // ASSERT: проект исчез из списка
    expect(find.text('To Delete'), findsNothing);
  });

  testWidgets(
    'При загрузке показывает только ACTIVE-проекты в сайдбаре',
    (tester) async {
      // ARRANGE
      final activeProject = Project(
        id: '1',
        name: 'Активный проект',
        colorId: '0',
        status: 'ACTIVE',
      );
      final completedProject = Project(
        id: '2',
        name: 'Завершённый проект',
        colorId: '0',
        status: 'COMPLETED',
      );
      final canceledProject = Project(
        id: '3',
        name: 'Отменённый проект',
        colorId: '0',
        status: 'CANCELED',
      );

      when(mockProjectService.getProjects()).thenAnswer(
        (_) async => [activeProject, completedProject, canceledProject],
      );

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShellScreen(
            projectService: mockProjectService,
            taskService: mockTaskService,
            auth: mockFirebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT: в сайдбаре только активный проект
      expect(find.text('Активный проект'), findsOneWidget);
      expect(find.text('Завершённый проект'), findsNothing);
      expect(find.text('Отменённый проект'), findsNothing);
    },
  );

  testWidgets(
    'Проект исчезает из сайдбара при смене статуса на COMPLETED через стрим',
    (tester) async {
      // ARRANGE
      final project = Project(
        id: '1',
        name: 'Мой проект',
        colorId: '0',
        status: 'ACTIVE',
      );
      final archivedProject = Project(
        id: '1',
        name: 'Мой проект',
        colorId: '0',
        status: 'COMPLETED',
      );

      when(mockProjectService.getProjects()).thenAnswer((_) async => [project]);

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShellScreen(
            projectService: mockProjectService,
            taskService: mockTaskService,
            auth: mockFirebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Мой проект'), findsOneWidget);

      // Эмулируем архивацию через стрим
      projectUpdateController.add(archivedProject);
      await tester.pumpAndSettle();

      // ASSERT: проект исчез из сайдбара
      expect(find.text('Мой проект'), findsNothing);
    },
  );

  testWidgets(
    'При архивации текущего проекта переключается на Входящие',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      // ARRANGE
      final project = Project(
        id: '1',
        name: 'Проект для архивации',
        colorId: '0',
        status: 'ACTIVE',
      );
      final archivedProject = Project(
        id: '1',
        name: 'Проект для архивации',
        colorId: '0',
        status: 'CANCELED',
      );

      when(mockProjectService.getProjects()).thenAnswer((_) async => [project]);
      when(
        mockTaskService.getTasksByProject(projectId: anyNamed('projectId')),
      ).thenAnswer((_) async => []);
      when(
        mockTaskService.getTasks(
          offset: anyNamed('offset'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => []);

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShellScreen(
            projectService: mockProjectService,
            taskService: mockTaskService,
            auth: mockFirebaseAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Открываем проект через сайдбар
      await tester.tap(find.text('Проект для архивации'));
      await tester.pumpAndSettle();

      // Архивируем проект через стрим
      projectUpdateController.add(archivedProject);
      await tester.pumpAndSettle();

      // ASSERT: проект исчез из сайдбара, переключились на "Входящие"
      // (текст "Входящие" есть и в сайдбаре-пункте меню, и в AppBar InboxScreen)
      expect(find.text('Проект для архивации'), findsNothing);
      expect(find.text('Входящие'), findsWidgets);
    },
  );
}
