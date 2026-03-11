import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';
import 'ai_review_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late AiReviewService service;

  setUp(() {
    mockDio = MockDio();
    service = AiReviewService(dio: mockDio);
  });

  Response<dynamic> ok(dynamic data) => Response(
        requestOptions: RequestOptions(path: ''),
        data: data,
        statusCode: 200,
      );

  DioException notFound() => DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      );

  DioException networkError() =>
      DioException(requestOptions: RequestOptions(path: ''));

  final reviewJson = {
    'id': 'r1',
    'is_active': true,
    'created_at': '2024-02-25T14:32:00Z',
    'task_id': 't1',
    'project_id': null,
    'comment': {
      'verdict': 'Задача сформулирована размыто',
      'score': 7,
      'questions': ['Нет глагола', 'Нет срока'],
    },
  };

  final shortJson = {
    'id': 'r1',
    'is_active': true,
    'task_id': 't1',
    'project_id': null,
  };

  // ─── Task reviews ──────────────────────────────────────────────────────────

  group('getActiveTaskReview', () {
    test('возвращает AIReviewRead при 200', () async {
      when(mockDio.get(any)).thenAnswer((_) async => ok(reviewJson));

      final result = await service.getActiveTaskReview('t1');

      expect(result, isA<AIReviewRead>());
      expect(result!.id, 'r1');
      expect(result.comment.score, 7);
      verify(mockDio.get('/tasks/t1/active')).called(1);
    });

    test('возвращает null при 404', () async {
      when(mockDio.get(any)).thenThrow(notFound());

      final result = await service.getActiveTaskReview('t1');

      expect(result, isNull);
    });

    test('возвращает null при сетевой ошибке', () async {
      when(mockDio.get(any)).thenThrow(networkError());

      final result = await service.getActiveTaskReview('t1');

      expect(result, isNull);
    });
  });

  group('getTaskReviewHistory', () {
    test('возвращает список AIReviewShort', () async {
      when(mockDio.get(any)).thenAnswer((_) async => ok([shortJson]));

      final result = await service.getTaskReviewHistory('t1');

      expect(result, isA<List<AIReviewShort>>());
      expect(result.length, 1);
      expect(result.first.id, 'r1');
      expect(result.first.isActive, true);
      verify(mockDio.get('/tasks/t1/history')).called(1);
    });

    test('возвращает пустой список при ошибке', () async {
      when(mockDio.get(any)).thenThrow(networkError());

      final result = await service.getTaskReviewHistory('t1');

      expect(result, isEmpty);
    });
  });

  group('runTaskReview', () {
    test('возвращает celery_task_id', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => ok({'celery_task_id': 'celery-123'}),
      );

      final result = await service.runTaskReview('t1');

      expect(result, 'celery-123');
      verify(mockDio.post('/tasks/t1/run')).called(1);
    });

    test('fallback на task_id если celery_task_id отсутствует', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => ok({'task_id': 'task-456'}),
      );

      final result = await service.runTaskReview('t1');

      expect(result, 'task-456');
    });
  });

  // ─── Project reviews ────────────────────────────────────────────────────────

  group('getActiveProjectReview', () {
    test('возвращает AIReviewRead при 200', () async {
      final json = {...reviewJson, 'task_id': null, 'project_id': 'p1'};
      when(mockDio.get(any)).thenAnswer((_) async => ok(json));

      final result = await service.getActiveProjectReview('p1');

      expect(result, isA<AIReviewRead>());
      expect(result!.projectId, 'p1');
      verify(mockDio.get('/projects/p1/active')).called(1);
    });

    test('возвращает null при 404', () async {
      when(mockDio.get(any)).thenThrow(notFound());

      final result = await service.getActiveProjectReview('p1');

      expect(result, isNull);
    });
  });

  group('getProjectReviewHistory', () {
    test('возвращает список AIReviewShort', () async {
      final json = {...shortJson, 'task_id': null, 'project_id': 'p1'};
      when(mockDio.get(any)).thenAnswer((_) async => ok([json]));

      final result = await service.getProjectReviewHistory('p1');

      expect(result.length, 1);
      expect(result.first.projectId, 'p1');
      verify(mockDio.get('/projects/p1/history')).called(1);
    });
  });

  group('runProjectReview', () {
    test('возвращает celery_task_id', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => ok({'celery_task_id': 'celery-789'}),
      );

      final result = await service.runProjectReview('p1');

      expect(result, 'celery-789');
      verify(mockDio.post('/projects/p1/run')).called(1);
    });
  });

  // ─── Shared ─────────────────────────────────────────────────────────────────

  group('getReviewById', () {
    test('возвращает AIReviewRead', () async {
      when(mockDio.get(any)).thenAnswer((_) async => ok(reviewJson));

      final result = await service.getReviewById('r1');

      expect(result.id, 'r1');
      expect(result.comment.verdict, 'Задача сформулирована размыто');
      verify(mockDio.get('/r1')).called(1);
    });
  });

  group('getReviewStatus', () {
    test('возвращает статус done', () async {
      when(mockDio.get(any)).thenAnswer((_) async => ok({'status': 'done'}));

      final result = await service.getReviewStatus('celery-123');

      expect(result, 'done');
      verify(mockDio.get('/status/celery-123')).called(1);
    });

    test('возвращает error при сетевой ошибке', () async {
      when(mockDio.get(any)).thenThrow(networkError());

      final result = await service.getReviewStatus('celery-123');

      expect(result, 'error');
    });
  });
}
