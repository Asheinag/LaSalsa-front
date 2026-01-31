import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    // Когда экран просит список задач - возвращаем пустоту
    when(
      mockTaskService.getTodayTasks(
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => []);

    // Когда экран создает задачу - возвращаем фейковую задачу
    when(
      mockTaskService.createTask(
        taskName: anyNamed('taskName'),
        plannedAt: anyNamed(
          'plannedAt',
        ), // Нам важно, что этот параметр придет!
      ),
    ).thenAnswer(
      (_) async => Task(
        id: '123',
        name: 'New Task',
        description: '',
        status: 'TODO',
        plannedAt: DateTime.now(),
      ),
    );

    // 2. Рендерим экран, передавая мок
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );

    // Ждем окончания загрузки (ProgressIndicator должен уйти)
    await tester.pumpAndSettle();

    // 3. Находим поле ввода и кнопку
    final inputFinder = find.byType(TextField);
    final buttonFinder = find.byType(
      IconButton,
    ); // Кнопка отправки в QuickAddTaskBar

    // 4. Вводим текст
    await tester.enterText(inputFinder, 'Купить молоко');
    await tester.pump();

    // 5. Жмем отправить
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(); // Ждем завершения асинхронной операции

    // 6. ПРОВЕРКА - убедимся, что createTask вызвался с правильными параметрами
    verify(
      mockTaskService.createTask(
        taskName: 'Купить молоко', // Тут конкретное значение, named не нужен
        // ИСПРАВЛЕНИЕ: Добавляем named: 'plannedAt'
        plannedAt: argThat(
          predicate<DateTime?>((date) {
            if (date == null) return false;
            final now = DateTime.now();
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }),
          named: 'plannedAt', // <--- ВОТ ЭТОГО НЕ ХВАТАЛО
        ),

        // Для остальных используем anyNamed, который уже внутри имеет named
        description: anyNamed('description'),
        projectId: anyNamed('projectId'),
        parentId: anyNamed('parentId'),
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

    // Mock the creator as well to avoid errors on add
    when(mockTaskService.createTask(taskName: anyNamed('taskName')))
        .thenAnswer((_) async => Task(id: '3', name: 'New', description: '', status: 'TODO'));

    // ACT
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );
    await tester.pumpAndSettle(); // Wait for fetch and UI update

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

    // Mock fetch
    when(mockTaskService.getTodayTasks(
            offset: anyNamed('offset'), limit: anyNamed('limit')))
        .thenAnswer((_) async => [initialTask]);

    // Mock update
    when(mockTaskService.updateTaskStatus(
            taskId: '1', taskStatus: 'DONE'))
        .thenAnswer((_) async => updatedTask);
    
    // Mock the creator as well
    when(mockTaskService.createTask(taskName: anyNamed('taskName')))
        .thenAnswer((_) async => Task(id: '3', name: 'New', description: '', status: 'TODO'));

    // ACT
    await tester.pumpWidget(
      MaterialApp(home: TodayScreen(service: mockTaskService)),
    );
    await tester.pumpAndSettle();

    // Find the checkbox within the list item for our specific task
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
