import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/models/task.dart';

void main() {
  test('Task copyWith updates provided fields', () {
    final original = Task(
      id: '1',
      name: 'Old',
      description: 'Desc',
      status: 'TODO',
    );
    final updated = original.copyWith(name: 'New', status: 'DONE');
    expect(updated.name, 'New');
    expect(updated.status, 'DONE');
    expect(updated.description, original.description);
    expect(updated.id, original.id);
  });

  test('Task fromJson parses date fields', () {
    final json = {
      'id': 1,
      'name': 'Json task',
      'description': 'Desc',
      'status': 'IN_PROGRESS',
      'planned_at': '2024-02-01T12:00:00.000Z',
      'closed_at': '2024-02-02T12:00:00.000Z',
    };
    final task = Task.fromJson(json);
    expect(task.id, '1');
    expect(task.name, 'Json task');
    expect(task.plannedAt, DateTime.parse('2024-02-01T12:00:00.000Z'));
    expect(task.closedAt, DateTime.parse('2024-02-02T12:00:00.000Z'));
  });

  test('Task toJson serializes plannedAt', () {
    final task = Task(
      id: '1',
      name: 'Test',
      description: 'Desc',
      status: 'TODO',
      plannedAt: DateTime.parse('2024-02-01T12:00:00.000Z'),
    );
    final json = task.toJson();
    expect(json['name'], 'Test');
    expect(json['planned_at'], '2024-02-01T12:00:00.000Z');
  });
}
