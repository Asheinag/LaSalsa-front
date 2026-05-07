import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';

void main() {
  // group - это способ сгруппировать несколько связанных тестов
  group('Task Model Tests', () {
    // test - это объявление одного конкретного тестового сценария
    test('copyWith should update only the specified fields', () {
      // ARRANGE (Подготовка)
      // Создаем исходный объект Task
      final originalTask = Task(
        id: '1',
        name: 'Initial Name',
        description: 'Initial Desc',
        status: 'TODO',
      );

      // ACT (Действие)
      // Вызываем метод, который мы хотим протестировать
      final updatedTask = originalTask.copyWith(name: 'Updated Name');

      // ASSERT (Проверка)
      // expect - это главная функция проверки. Она сравнивает фактический
      // результат (actual) с ожидаемым (matcher).
      expect(updatedTask.id, originalTask.id); // ID должен остаться прежним
      expect(updatedTask.name, 'Updated Name'); // Имя должно измениться
      expect(
        updatedTask.status,
        originalTask.status,
      ); // Статус должен остаться прежним
    });
  });
  // Новая группа тестов специально для JSON
  group('Task Model from/to JSON', () {
    test('should correctly deserialize from JSON', () {
      // ARRANGE: Полный и корректный JSON
      final json = {
        'id': 101,
        'name': 'Task from JSON',
        'description': 'Desc from JSON',
        'status': 'DONE',
        'planned_at': '2025-09-28T10:00:00.000Z',
      };

      // ACT
      final task = Task.fromJson(json);

      // ASSERT
      expect(task.id, '101');
      expect(task.name, 'Task from JSON');
      expect(task.status, 'DONE');
      expect(task.plannedAt, isNotNull);
    });

    test('should handle missing optional fields in JSON', () {
      // ARRANGE: JSON, в котором нет необязательных полей planned_at и project_id
      final json = {
        'id': 102,
        'name': 'Simple Task',
        'description': '',
        'status': 'TODO',
      };

      // ACT
      final task = Task.fromJson(json);

      // ASSERT: Проверяем, что необязательные поля стали null
      expect(task.id, '102');
      expect(task.plannedAt, isNull);
      expect(task.projectId, isNull);
    });

    test('should handle missing required fields with defaults', () {
      // ARRANGE: JSON, в котором "забыли" положить name
      final json = {'id': 103, 'description': '', 'status': 'TODO'};

      // ACT
      final task = Task.fromJson(json);

      // ASSERT: Проверяем, что сработало наше значение по умолчанию ''
      expect(task.name, '');
    });

    test('should parse recurring_task_id from JSON', () {
      final json = {
        'id': 105,
        'name': 'Recurring Task',
        'description': '',
        'status': 'TODO',
        'recurring_task_id': 7,
      };
      final task = Task.fromJson(json);
      expect(task.recurringTaskId, '7');
    });

    test('recurring_task_id is null when not in JSON', () {
      final json = {
        'id': 106,
        'name': 'Normal Task',
        'description': '',
        'status': 'TODO',
      };
      final task = Task.fromJson(json);
      expect(task.recurringTaskId, isNull);
    });

    test('should ignore extra fields in JSON', () {
      // ARRANGE: В JSON есть лишнее поле "color"
      final json = {
        'id': 104,
        'name': 'Task with extra data',
        'description': '',
        'status': 'TODO',
        'color': 'red',
        'is_urgent': true,
      };

      // ACT
      final task = Task.fromJson(json);

      // ASSERT: Просто проверяем, что задача создалась корректно,
      // а лишние поля были просто проигнорированы
      expect(task.id, '104');
      expect(task.name, 'Task with extra data');
    });
  });
}
