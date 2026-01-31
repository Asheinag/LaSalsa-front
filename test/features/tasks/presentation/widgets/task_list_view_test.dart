import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_base.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_list_view.dart';

void main() {
  group('Task List Tests', () {
    testWidgets('Check Loading show Progress Indicator', (
      WidgetTester tester,
    ) async {
      Future<List<Task>> fakeFetcher() async {
        await Future.delayed(const Duration(seconds: 1));
        return [
          Task(id: '1', name: 'Test Task', description: '', status: 'TODO'),
        ];
      }

      Future<Task> fakeCreator(String title) async {
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
      expect(find.byType(TaskListBase), findsNothing);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TaskListBase), findsOneWidget);
      expect(find.text('Test Task'), findsOneWidget);
    });
    testWidgets('Check empty message', (WidgetTester tester) async {
      Future<List<Task>> fakeFetcher() async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      }

      Future<Task> fakeCreator(String title) async {
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
      expect(find.byType(TaskListBase), findsNothing);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TaskListBase), findsOneWidget);
      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('Check error message on fetch failure',
        (WidgetTester tester) async {
      // ARRANGE: Наш загрузчик теперь просто бросает исключение
      Future<List<Task>> fakeFetcher() async {
        throw Exception('Failed to load');
      }

      Future<Task> fakeCreator(String title) async {
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
  });
}
