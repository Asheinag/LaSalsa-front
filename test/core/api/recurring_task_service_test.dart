import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';
import 'recurring_task_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late RecurringTaskService service;

  setUp(() {
    mockDio = MockDio();
    service = RecurringTaskService(dio: mockDio);
  });

  Response<dynamic> ok(dynamic data, {int statusCode = 200}) => Response(
        requestOptions: RequestOptions(path: ''),
        data: data,
        statusCode: statusCode,
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

  final recurringJson = {
    'id': 1,
    'name': 'Написать отчёт',
    'description': null,
    'project_id': null,
    'task_id': 42,
    'frequency': 'weekly',
    'days': [0, 2, 4],
    'timezone': 'Europe/Moscow',
    'is_active': true,
    'next_run_at': '2026-05-09T00:00:00Z',
    'last_run_at': null,
  };

  group('getByTaskId', () {
    test('возвращает RecurringTask при 200', () async {
      when(mockDio.get(any)).thenAnswer((_) async => ok(recurringJson));

      final result = await service.getByTaskId('42');

      expect(result, isA<RecurringTask>());
      expect(result!.id, 1);
      expect(result.frequency, RecurringFrequency.weekly);
      expect(result.days, [0, 2, 4]);
      verify(mockDio.get('/by-task/42')).called(1);
    });

    test('возвращает null при 404', () async {
      when(mockDio.get(any)).thenThrow(notFound());

      final result = await service.getByTaskId('42');

      expect(result, isNull);
    });

    test('возвращает null при сетевой ошибке', () async {
      when(mockDio.get(any)).thenThrow(networkError());

      final result = await service.getByTaskId('42');

      expect(result, isNull);
    });
  });

  group('create', () {
    test('возвращает RecurringTask при успехе', () async {
      when(mockDio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => ok(recurringJson, statusCode: 201));

      final result = await service.create({
        'task_id': 42,
        'frequency': 'weekly',
        'days': [0, 2, 4],
        'timezone': 'Europe/Moscow',
      });

      expect(result, isA<RecurringTask>());
      expect(result.id, 1);
      verify(mockDio.post('/', data: anyNamed('data'))).called(1);
    });

    test('бросает Exception при ошибке', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenThrow(networkError());

      expect(
        () => service.create({'frequency': 'daily', 'days': []}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('update', () {
    test('возвращает обновлённый RecurringTask', () async {
      final updatedJson = {...recurringJson, 'frequency': 'daily', 'days': []};
      when(mockDio.patch(any, data: anyNamed('data')))
          .thenAnswer((_) async => ok(updatedJson));

      final result = await service.update(1, {'frequency': 'daily', 'days': []});

      expect(result.frequency, RecurringFrequency.daily);
      verify(mockDio.patch('/1', data: anyNamed('data'))).called(1);
    });

    test('бросает Exception при ошибке', () async {
      when(mockDio.patch(any, data: anyNamed('data'))).thenThrow(networkError());

      expect(
        () => service.update(1, {'frequency': 'daily'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('delete', () {
    test('завершается без ошибки при 204', () async {
      when(mockDio.delete(any))
          .thenAnswer((_) async => ok(null, statusCode: 204));

      await expectLater(service.delete(1), completes);
      verify(mockDio.delete('/1')).called(1);
    });

    test('бросает Exception при ошибке', () async {
      when(mockDio.delete(any)).thenThrow(networkError());

      expect(
        () => service.delete(1),
        throwsA(isA<Exception>()),
      );
    });
  });
}
