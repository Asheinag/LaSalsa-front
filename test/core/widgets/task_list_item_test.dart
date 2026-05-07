import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/widgets/task_list_item.dart';

void main() {
  Widget buildItem(Task task) {
    return MaterialApp(
      home: Scaffold(
        body: TaskListItem(
          task: task,
          onStatusChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('не показывает иконку повторения для обычной задачи', (tester) async {
    final task = Task(id: '1', name: 'Задача', description: '', status: 'TODO');
    await tester.pumpWidget(buildItem(task));
    expect(find.byIcon(Icons.repeat), findsNothing);
  });

  testWidgets('показывает иконку повторения для задачи с recurringTaskId', (tester) async {
    final task = Task(id: '1', name: 'Задача', description: '', status: 'TODO', recurringTaskId: '42');
    await tester.pumpWidget(buildItem(task));
    expect(find.byIcon(Icons.repeat), findsOneWidget);
  });
}
