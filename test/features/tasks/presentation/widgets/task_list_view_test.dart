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

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
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

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListView(
            title: 'Test Task List',
            fetcher: fakeFetcher,
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
  });
}
