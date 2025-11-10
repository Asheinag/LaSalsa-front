import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'task_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late TaskService taskService;

  setUp(() {
    mockDio = MockDio();
    taskService = TaskService(dio: mockDio);
  });

  // Группа тестов для нашего сервиса
  group('TaskService Tests', () {
    // Объявляем сервис, который будем тестировать

    test('getTodayTasks should return a list of tasks', () async {
      // ACT (Действие)
      // Вызываем асинхронный метод и дожидаемся результата
      final fakeResponse = {
        "data": [
          {"id": 1, "name": "Test Task 1", "description": "", "status": "TODO"},
        ],
      };

      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse['data'], // Важно передать сам список
          statusCode: 200,
        ),
      );

      final tasks = await taskService.getTodayTasks(limit: '0', offset: '20');

      // ASSERT (Проверка)
      // Проверяем, что результат не просто что-то, а именно List<Task>
      expect(tasks, isA<List<Task>>());
      // Дополнительно можем проверить, что список не пустой
      expect(tasks, isNotEmpty);

      verify(mockDio.get('/tasks/today/?offset=20&limit=0')).called(1);
    });

    test('getTodayTasks should return tasks with correct data', () async {
      final fakeResponse = {
        "data": [
          {
            "id": 1,
            "name": "Позвонить клиенту по договору",
            "description": "Позвонить клиенту по договору",
            "status": "TODO",
          },
        ],
      };

      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse['data'], // Важно передать сам список
          statusCode: 200,
        ),
      );
      // ACT
      final tasks = await taskService.getTodayTasks(limit: '0', offset: '20');

      // ASSERT
      // Можем проверить конкретную задачу в списке
      final firstTask = tasks.first;
      expect(firstTask.id, '1');
      expect(firstTask.name, 'Позвонить клиенту по договору');
      expect(firstTask.description, 'Позвонить клиенту по договору');
      expect(firstTask.status, 'TODO');

      verify(mockDio.get('/tasks/today/?offset=20&limit=0')).called(1);
    });

    test('createTask should create and return new task ', () async {
      final fakeResponse = {
        "id": 1,
        "name": "New Task",
        "description": "",
        "status": "TODO",
      };

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse,
          statusCode: 201,
        ),
      );

      // ACT
      final newTask = await taskService.createTask(taskName: 'New Task');

      // ASSERT
      expect(newTask, isA<Task>());
      expect(newTask.id, '1');
      expect(newTask.name, 'New Task');
      expect(newTask.description, '');
      expect(newTask.status, 'TODO');

      verify(
        mockDio.post(
          '/tasks', // Проверяем, что URL был сформирован правильно
          data: {
            'name': 'New Task',
            'description': ''
          }, // Проверяем, что в теле запроса были отправлены правильные данные
        ),
      ).called(1);

    });

    test('updateTaskStatus should update and return updated task', () async {
      final fakeResponse = {
        "id": 1,
        "name": "Updated Task",
        "description": "",
        "status": "DONE",
      };

      when(mockDio.patch(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse,
          statusCode: 200,
        ),
      );

      // ACT
      final updatedTask = await taskService.updateTaskStatus(
        taskId: '1',
        taskStatus: 'DONE',
      );

      // ASSERT
      expect(updatedTask, isA<Task>());
      expect(updatedTask.id, '1');
      expect(updatedTask.name, 'Updated Task');
      expect(updatedTask.description, '');
      expect(updatedTask.status, 'DONE');

      verify(
        mockDio.patch(
          '/tasks/status', // Проверяем, что URL был сформирован правильно
          data: {
            'id': '1',
            'status': 'DONE',
          }, // Проверяем, что в теле запроса были отправлены правильные данные
        ),
      ).called(1);
    });
  });
}
