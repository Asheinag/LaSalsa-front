import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';
import 'package:kabachok_lasalsa_front/features/recurring/presentation/widgets/recurrence_section.dart';
import 'recurrence_section_test.mocks.dart';

@GenerateMocks([RecurringTaskService])
void main() {
  late MockRecurringTaskService mockService;

  final testRecurring = RecurringTask(
    id: 1,
    name: 'Test',
    frequency: RecurringFrequency.daily,
    days: [],
    timezone: 'UTC',
    isActive: true,
    nextRunAt: DateTime.utc(2026, 5, 10),
  );

  setUp(() {
    mockService = MockRecurringTaskService();
  });

  Widget buildSection({RecurringTask? recurring}) {
    when(mockService.getByTaskId(any))
        .thenAnswer((_) async => recurring);
    return MaterialApp(
      home: Scaffold(
        body: RecurrenceSection(
          taskId: '42',
          taskName: 'Test Task',
          recurringTaskService: mockService,
        ),
      ),
    );
  }

  testWidgets('показывает индикатор загрузки пока грузит', (tester) async {
    final completer = Completer<RecurringTask?>();
    when(mockService.getByTaskId(any)).thenAnswer((_) => completer.future);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecurrenceSection(
          taskId: '42',
          taskName: 'Test Task',
          recurringTaskService: mockService,
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(null);
  });

  testWidgets('показывает кнопку "+ Добавить" когда повторение не настроено',
      (tester) async {
    await tester.pumpWidget(buildSection(recurring: null));
    await tester.pumpAndSettle();

    expect(find.text('ПОВТОРЕНИЕ'), findsOneWidget);
    expect(find.text('+ Добавить'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsNothing);
  });

  testWidgets('показывает расписание и кнопки когда повторение настроено',
      (tester) async {
    await tester.pumpWidget(buildSection(recurring: testRecurring));
    await tester.pumpAndSettle();

    expect(find.text('ПОВТОРЕНИЕ'), findsOneWidget);
    expect(find.text('Изменить'), findsOneWidget);
    expect(find.text('Каждый день'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
  });

  testWidgets('показывает диалог подтверждения при нажатии "Удалить"',
      (tester) async {
    when(mockService.delete(any)).thenAnswer((_) async {});
    await tester.pumpWidget(buildSection(recurring: testRecurring));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Удалить повторение?'), findsOneWidget);
    expect(find.text('Задача останется, повторение будет отключено.'), findsOneWidget);
  });

  testWidgets('после подтверждения удаления секция переходит в пустое состояние',
      (tester) async {
    when(mockService.delete(any)).thenAnswer((_) async {});
    await tester.pumpWidget(buildSection(recurring: testRecurring));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    verify(mockService.delete(1)).called(1);
    expect(find.text('+ Добавить'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsNothing);
  });

  testWidgets('перезагружает при смене taskId', (tester) async {
    await tester.pumpWidget(buildSection(recurring: null));
    await tester.pumpAndSettle();

    when(mockService.getByTaskId(any))
        .thenAnswer((_) async => testRecurring);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurrenceSection(
            taskId: '99',
            taskName: 'Other Task',
            recurringTaskService: mockService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Каждый день'), findsOneWidget);
  });
}
