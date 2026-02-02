import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';

// Генерируем мок для Самого сервиса, а не для Dio
@GenerateMocks([TaskService])
import 'today_screen_test.mocks.dart';

void main() {
  late MockTaskService mockTaskService;

  setUp(() {
    mockTaskService = MockTaskService();
  });

  testWidgets('TodayScreen adds task with current date', (tester) async {
    // 1. Настраиваем моки
    when(
      mockTaskService.getTodayTasks(
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => []);

    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        plannedAt: anyNamed('plannedAt'),
      ),
    ).thenAnswer(
      (_) async => Task(id: '123', name: 'New Task', description: '', status: 'TODO'),
    );

    // 2. Рендерим экран
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );
    await tester.pumpAndSettle();

    // 3. Проверяем, что дата по умолчанию (сегодня) отображается
    final todayString = DateFormat('dd.MM').format(DateTime.now());
    expect(find.text(todayString), findsOneWidget);

    // 4. Вводим текст
    await tester.enterText(find.byType(TextField), 'Купить молоко');
    await tester.tap(find.byTooltip('Добавить задачу'));
    await tester.pumpAndSettle();

    // 5. ПРОВЕРКА
    verify(
      mockTaskService.createTask(
        taskName: 'Купить молоко',
        plannedAt: argThat(
          isA<DateTime>().having((date) {
            final now = DateTime.now();
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }, 'isToday', true),
          named: 'plannedAt',
        ),
      ),
    ).called(1);
  });

  testWidgets('TodayScreen should display tasks on successful fetch',
      (tester) async {
    // ARRANGE
    final fakeTasks = [
      Task(id: '1', name: 'Task 1', description: '', status: 'TODO'),
      Task(id: '2', name: 'Task 2', description: '', status: 'TODO'),
    ];

    when(
      mockTaskService.getTodayTasks(
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => fakeTasks);

    when(mockTaskService.createTask(
            taskName: anyNamed('taskName'), plannedAt: anyNamed('plannedAt')))
        .thenAnswer((_) async =>
            Task(id: '3', name: 'New', description: '', status: 'TODO'));

    // ACT
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
  });

  testWidgets('should call update service when a task is checked',
      (tester) async {
    // ARRANGE
    final initialTask =
        Task(id: '1', name: 'Task to be done', description: '', status: 'TODO');
    final updatedTask =
        Task(id: '1', name: 'Task to be done', description: '', status: 'DONE');

    when(mockTaskService.getTodayTasks(
            offset: anyNamed('offset'), limit: anyNamed('limit')))
        .thenAnswer((_) async => [initialTask]);

    when(mockTaskService.updateTaskStatus(
            taskId: '1', taskStatus: 'DONE'))
        .thenAnswer((_) async => updatedTask);

    when(mockTaskService.createTask(
            taskName: anyNamed('taskName'), plannedAt: anyNamed('plannedAt')))
        .thenAnswer((_) async =>
            Task(id: '3', name: 'New', description: '', status: 'TODO'));

    // ACT
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );
    await tester.pumpAndSettle();

    final checkboxFinder = find.descendant(
      of: find.widgetWithText(ListTile, 'Task to be done'),
      matching: find.byType(Checkbox),
    );

    expect(checkboxFinder, findsOneWidget);

    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // ASSERT
    verify(mockTaskService.updateTaskStatus(taskId: '1', taskStatus: 'DONE'))
        .called(1);
  });
}
