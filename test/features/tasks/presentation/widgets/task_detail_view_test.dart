import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_card.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_placeholder.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_detail_view.dart';
import 'task_detail_view_test.mocks.dart';

@GenerateMocks([TaskService, AiReviewService, RecurringTaskService])
void main() {
  late MockTaskService mockTaskService;
  late MockAiReviewService mockAiReviewService;
  late MockRecurringTaskService mockRecurringTaskService;

  final testTask = Task(
    id: 't1',
    name: 'Тестовая задача',
    description: 'Описание',
    status: 'TODO',
  );

  final testReview = AIReviewRead(
    id: 'r1',
    isActive: true,
    createdAt: DateTime.utc(2024, 2, 25, 14, 32),
    taskId: 't1',
    comment: AIReviewComment(
      verdict: 'Задача сформулирована размыто',
      score: 7,
      questions: ['Нет глагола действия', 'Нет срока'],
    ),
  );

  setUp(() {
    mockTaskService = MockTaskService();
    mockAiReviewService = MockAiReviewService();
    mockRecurringTaskService = MockRecurringTaskService();

    when(mockTaskService.taskUpdates).thenAnswer((_) => const Stream.empty());
    when(mockTaskService.taskDeletions).thenAnswer((_) => const Stream.empty());
    when(mockTaskService.getTaskDetails(taskId: anyNamed('taskId')))
        .thenAnswer((_) async => testTask);
    when(mockRecurringTaskService.getByTaskId(any))
        .thenAnswer((_) async => null);
  });

  Widget buildView({AIReviewRead? review}) {
    when(mockAiReviewService.getActiveTaskReview(any))
        .thenAnswer((_) async => review);

    return MaterialApp(
      home: Scaffold(
        body: TaskDetailView(
          task: testTask,
          taskService: mockTaskService,
          aiReviewService: mockAiReviewService,
          recurringTaskService: mockRecurringTaskService,
        ),
      ),
    );
  }

  group('TaskDetailView — AI Review секция', () {
    testWidgets('показывает спиннер пока грузится ревью', (tester) async {
      // Мок не разрешается сразу — используем Completer
      final completer = Completer<AIReviewRead?>();
      when(mockAiReviewService.getActiveTaskReview(any))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskDetailView(
            task: testTask,
            taskService: mockTaskService,
            aiReviewService: mockAiReviewService,
            recurringTaskService: mockRecurringTaskService,
          ),
        ),
      ));

      // Первый pump — состояние loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(null);
    });

    testWidgets('показывает плейсхолдер когда ревью нет', (tester) async {
      await tester.pumpWidget(buildView(review: null));
      await tester.pumpAndSettle();

      expect(find.byType(AiReviewPlaceholder), findsOneWidget);
      expect(find.byType(AiReviewCard), findsNothing);
    });

    testWidgets('показывает кнопку "Проверить задачу" в плейсхолдере',
        (tester) async {
      await tester.pumpWidget(buildView(review: null));
      await tester.pumpAndSettle();

      expect(find.text('Проверить задачу'), findsOneWidget);
    });

    testWidgets('показывает AiReviewCard когда ревью загружено', (tester) async {
      await tester.pumpWidget(buildView(review: testReview));
      await tester.pumpAndSettle();

      expect(find.byType(AiReviewCard), findsOneWidget);
      expect(find.byType(AiReviewPlaceholder), findsNothing);
    });

    testWidgets('отображает вердикт из ревью', (tester) async {
      await tester.pumpWidget(buildView(review: testReview));
      await tester.pumpAndSettle();

      expect(find.text('Задача сформулирована размыто'), findsOneWidget);
    });

    testWidgets('показывает кнопку "Обновить" при наличии ревью', (tester) async {
      await tester.pumpWidget(buildView(review: testReview));
      await tester.pumpAndSettle();

      expect(find.text('Обновить'), findsOneWidget);
    });

    testWidgets('не показывает кнопку "Обновить" когда ревью нет',
        (tester) async {
      await tester.pumpWidget(buildView(review: null));
      await tester.pumpAndSettle();

      expect(find.text('Обновить'), findsNothing);
    });

    testWidgets('нажатие "Проверить задачу" запускает ревью', (tester) async {
      when(mockAiReviewService.runTaskReview(any))
          .thenAnswer((_) async => 'celery-123');
      when(mockAiReviewService.getReviewStatus(any))
          .thenAnswer((_) async => 'pending');

      await tester.pumpWidget(buildView(review: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проверить задачу'));
      await tester.pump();

      // Состояние running — спиннер с текстом
      expect(find.text('Ментор анализирует задачу...'), findsOneWidget);
      verify(mockAiReviewService.runTaskReview('t1')).called(1);
    });

    testWidgets('после завершения поллинга показывает ревью', (tester) async {
      // Сначала нет ревью, потом появляется после статуса "done"
      var callCount = 0;
      when(mockAiReviewService.getActiveTaskReview(any)).thenAnswer((_) async {
        callCount++;
        return callCount >= 2 ? testReview : null;
      });
      when(mockAiReviewService.runTaskReview(any))
          .thenAnswer((_) async => 'celery-123');
      when(mockAiReviewService.getReviewStatus(any))
          .thenAnswer((_) async => 'done');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskDetailView(
            task: testTask,
            taskService: mockTaskService,
            aiReviewService: mockAiReviewService,
            recurringTaskService: mockRecurringTaskService,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Запускаем ревью
      await tester.tap(find.text('Проверить задачу'));
      await tester.pump();

      // Ждём поллинг (Timer.periodic каждые 2 сек)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(AiReviewCard), findsOneWidget);
    });
  });
}
