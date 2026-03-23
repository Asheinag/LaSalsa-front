import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/quick_add_task_bar.dart';

void main() {
  group('QuickAddTaskBar', () {
    testWidgets('автофокус при первом рендере', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddTaskBar(onTaskSubmitted: (_, _) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('фокус возвращается в поле после сабмита', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddTaskBar(
              onTaskSubmitted: (title, _) => submitted = title,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Тестовая задача');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitted, 'Тестовая задача');
      expect(find.text('Тестовая задача'), findsNothing); // поле очищено
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('пустой текст — сабмит не вызывается', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddTaskBar(onTaskSubmitted: (_, _) => callCount++),
          ),
        ),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
