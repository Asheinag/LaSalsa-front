import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';

void main() {
  final baseJson = {
    'id': 1,
    'name': 'Test Task',
    'description': null,
    'project_id': null,
    'task_id': 42,
    'timezone': 'Europe/Moscow',
    'is_active': true,
    'next_run_at': '2026-05-10T00:00:00Z',
    'last_run_at': null,
  };

  group('RecurringTask.fromJson', () {
    test('DAILY — парсит корректно', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
      });
      expect(r.frequency, RecurringFrequency.daily);
      expect(r.days, isEmpty);
      expect(r.id, 1);
      expect(r.taskId, 42);
    });

    test('WEEKLY — парсит дни недели', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'weekly',
        'days': [0, 2, 4],
      });
      expect(r.frequency, RecurringFrequency.weekly);
      expect(r.days, [0, 2, 4]);
    });

    test('MONTHLY — парсит числа месяца', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'monthly',
        'days': [1, 15],
      });
      expect(r.frequency, RecurringFrequency.monthly);
      expect(r.days, [1, 15]);
    });

    test('INTERVAL — парсит интервал', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'interval',
        'days': [3],
      });
      expect(r.frequency, RecurringFrequency.interval);
      expect(r.days, [3]);
    });

    test('next_run_at парсится в DateTime', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
      });
      expect(r.nextRunAt, DateTime.utc(2026, 5, 10));
    });

    test('last_run_at null — остаётся null', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
        'last_run_at': null,
      });
      expect(r.lastRunAt, isNull);
    });

    test('last_run_at заполнен — парсится', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
        'last_run_at': '2026-05-09T00:00:00Z',
      });
      expect(r.lastRunAt, DateTime.utc(2026, 5, 9));
    });
  });

  group('formatRecurrence', () {
    RecurringTask make(RecurringFrequency freq, List<int> days) {
      return RecurringTask(
        id: 1,
        name: 'x',
        frequency: freq,
        days: days,
        timezone: 'UTC',
        isActive: true,
        nextRunAt: DateTime.utc(2026, 5, 10),
      );
    }

    test('DAILY → "Каждый день"', () {
      expect(formatRecurrence(make(RecurringFrequency.daily, [])), 'Каждый день');
    });

    test('WEEKLY [0,2,4] → "Пн, Ср, Пт"', () {
      expect(formatRecurrence(make(RecurringFrequency.weekly, [0, 2, 4])), 'Пн, Ср, Пт');
    });

    test('WEEKLY [] → "Каждый день"', () {
      expect(formatRecurrence(make(RecurringFrequency.weekly, [])), 'Каждый день');
    });

    test('MONTHLY [1] → "1-го числа"', () {
      expect(formatRecurrence(make(RecurringFrequency.monthly, [1])), '1-го числа');
    });

    test('MONTHLY [1, 15] → "1-го и 15-го числа"', () {
      expect(formatRecurrence(make(RecurringFrequency.monthly, [1, 15])), '1-го и 15-го числа');
    });

    test('INTERVAL [1] → "Каждый день"', () {
      expect(formatRecurrence(make(RecurringFrequency.interval, [1])), 'Каждый день');
    });

    test('INTERVAL [3] → "Каждые 3 дня"', () {
      expect(formatRecurrence(make(RecurringFrequency.interval, [3])), 'Каждые 3 дня');
    });

    test('INTERVAL [7] → "Каждые 7 дней"', () {
      expect(formatRecurrence(make(RecurringFrequency.interval, [7])), 'Каждые 7 дней');
    });

    test('INTERVAL [21] → "Каждые 21 день"', () {
      expect(formatRecurrence(make(RecurringFrequency.interval, [21])), 'Каждый 21 день');
    });
  });

  group('Task.recurringTaskId', () {
    test('fromJson парсит recurring_task_id', () {
      // проверяется отдельно в task_model_test
      // здесь просто убеждаемся что поле taskId в RecurringTask парсится
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
        'task_id': 99,
      });
      expect(r.taskId, 99);
    });

    test('task_id null допустим', () {
      final r = RecurringTask.fromJson({
        ...baseJson,
        'frequency': 'daily',
        'days': [],
        'task_id': null,
      });
      expect(r.taskId, isNull);
    });
  });
}
