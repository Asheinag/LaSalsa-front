import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_base.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';

void main() {
  group('Task List Tests', () {
    testWidgets('Check Loading show Progress Indicator', (
      WidgetTester tester,
    ) async {
      Future<List<Task>> fakeFetcher(int offset, int limit) async {
        await Future.delayed(const Duration(seconds: 1));
        return [
          Task(id: '1', name: 'Test Task', description: '', status: 'TODO'),
        ];
      }

      Future<Task> fakeCreator(String title, DateTime? plannedAt) async {
        return Task(id: '2', name: title, description: '', status: 'TODO');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
            creator: fakeCreator,
            emptyListMessage: 'Empty',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Task'), findsOneWidget);
    });
    testWidgets('Check empty message', (WidgetTester tester) async {
      Future<List<Task>> fakeFetcher(int offset, int limit) async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      }

      Future<Task> fakeCreator(String title, DateTime? plannedAt) async {
        return Task(id: '2', name: title, description: '', status: 'TODO');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
            creator: fakeCreator,
            emptyListMessage: 'No tasks available',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('Check error message on fetch failure',
        (WidgetTester tester) async {
      // ARRANGE: Наш загрузчик теперь просто бросает исключение
      Future<List<Task>> fakeFetcher(int offset, int limit) async {
        throw Exception('Failed to load');
      }

      Future<Task> fakeCreator(String title, DateTime? plannedAt) async {
        return Task(id: '2', name: title, description: '', status: 'TODO');
      }

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
            creator: fakeCreator,
            emptyListMessage: 'Empty',
          ),
        ),
      );

      // ASSERT: Сначала индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TaskListBase), findsNothing);

      // ACT: Ждем завершения
      await tester.pumpAndSettle();

      // ASSERT: Теперь - сообщение об ошибке
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TaskListBase), findsNothing);
      expect(find.text('Не удалось загрузить задачи.'), findsOneWidget);
    });

    testWidgets('Shows initial date in QuickAddTaskBar',
        (WidgetTester tester) async {
      // ARRANGE
      Future<List<Task>> fakeFetcher(int offset, int limit) async => [];
      Future<Task> fakeCreator(String title, DateTime? plannedAt) async =>
          Task(id: '1', name: title, description: '', status: 'TODO');
      final initialDate = DateTime(2025, 5, 10);

      // ACT
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
            creator: fakeCreator,
            emptyListMessage: 'Empty',
            initialDate: initialDate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text(DateFormat('dd.MM').format(initialDate)), findsOneWidget);
    });
  });

  group('Поведение hideCompleted', () {
    final todoTask = Task(
      id: '1',
      name: 'Активная задача',
      description: '',
      status: 'TODO',
    );
    final doneTask = Task(
      id: '2',
      name: 'Выполненная задача',
      description: '',
      status: 'DONE',
    );

    Future<Task> fakeCreator(String title, DateTime? plannedAt) async =>
        Task(id: '3', name: title, description: '', status: 'TODO');

    testWidgets(
      'hideCompleted: false — показывает все задачи включая DONE',
      (tester) async {
        // ARRANGE
        Future<List<Task>> fetcher(int offset, int limit) async => [todoTask, doneTask];

        // ACT
        await tester.pumpWidget(
          MaterialApp(
            home: TaskListView(
              title: 'Test',
              fetcher: fetcher,
              creator: fakeCreator,
              emptyListMessage: 'Пусто',
              hideCompleted: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ASSERT: обе задачи видны, тоггл не отображается
        expect(find.text('Активная задача'), findsOneWidget);
        expect(find.text('Выполненная задача'), findsOneWidget);
        expect(find.textContaining('Выполнено ('), findsNothing);
      },
    );

    testWidgets(
      'hideCompleted: true — скрывает DONE-задачи по умолчанию',
      (tester) async {
        // ARRANGE
        Future<List<Task>> fetcher(int offset, int limit) async => [todoTask, doneTask];

        // ACT
        await tester.pumpWidget(
          MaterialApp(
            home: TaskListView(
              title: 'Test',
              fetcher: fetcher,
              creator: fakeCreator,
              emptyListMessage: 'Пусто',
              hideCompleted: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ASSERT: только активная задача видна
        expect(find.text('Активная задача'), findsOneWidget);
        expect(find.text('Выполненная задача'), findsNothing);
      },
    );

    testWidgets(
      'hideCompleted: true — показывает кнопку "Выполнено (N)" при наличии DONE-задач',
      (tester) async {
        // ARRANGE
        Future<List<Task>> fetcher(int offset, int limit) async => [todoTask, doneTask];

        // ACT
        await tester.pumpWidget(
          MaterialApp(
            home: TaskListView(
              title: 'Test',
              fetcher: fetcher,
              creator: fakeCreator,
              emptyListMessage: 'Пусто',
              hideCompleted: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ASSERT: тоггл-кнопка с правильным счётчиком
        expect(find.text('Выполнено (1)'), findsOneWidget);
      },
    );

    testWidgets(
      'По клику на тоггл DONE-задачи раскрываются и текст кнопки меняется',
      (tester) async {
        // ARRANGE
        Future<List<Task>> fetcher(int offset, int limit) async => [todoTask, doneTask];

        // ACT
        await tester.pumpWidget(
          MaterialApp(
            home: TaskListView(
              title: 'Test',
              fetcher: fetcher,
              creator: fakeCreator,
              emptyListMessage: 'Пусто',
              hideCompleted: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Убеждаемся, что DONE-задача скрыта
        expect(find.text('Выполненная задача'), findsNothing);

        // ACT: нажимаем тоггл
        await tester.tap(find.text('Выполнено (1)'));
        await tester.pumpAndSettle();

        // ASSERT: DONE-задача видна, кнопка сменила текст
        expect(find.text('Выполненная задача'), findsOneWidget);
        expect(find.text('Скрыть выполненные'), findsOneWidget);
      },
    );

    testWidgets(
      'hideCompleted: true без DONE-задач — тоггл не отображается',
      (tester) async {
        // ARRANGE: только TODO задачи
        Future<List<Task>> fetcher(int offset, int limit) async => [todoTask];

        // ACT
        await tester.pumpWidget(
          MaterialApp(
            home: TaskListView(
              title: 'Test',
              fetcher: fetcher,
              creator: fakeCreator,
              emptyListMessage: 'Пусто',
              hideCompleted: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ASSERT: задача видна, тоггл отсутствует
        expect(find.text('Активная задача'), findsOneWidget);
        expect(find.textContaining('Выполнено ('), findsNothing);
        expect(find.text('Скрыть выполненные'), findsNothing);
      },
    );
  });
}
