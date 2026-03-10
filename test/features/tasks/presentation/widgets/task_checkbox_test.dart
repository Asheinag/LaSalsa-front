import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_checkbox.dart';

void main() {
  Widget buildCheckbox({required bool value, required ValueChanged<bool> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TaskCheckbox(value: value, onChanged: onChanged),
        ),
      ),
    );
  }

  group('TaskCheckbox', () {
    testWidgets('renders without error when unchecked', (tester) async {
      await tester.pumpWidget(buildCheckbox(value: false, onChanged: (_) {}));
      expect(find.byType(TaskCheckbox), findsOneWidget);
    });

    testWidgets('renders without error when checked', (tester) async {
      await tester.pumpWidget(buildCheckbox(value: true, onChanged: (_) {}));
      await tester.pump(); // allow animation to start
      expect(find.byType(TaskCheckbox), findsOneWidget);
    });

    testWidgets('calls onChanged(true) when unchecked and tapped', (tester) async {
      bool? received;
      await tester.pumpWidget(buildCheckbox(value: false, onChanged: (val) => received = val));
      await tester.tap(find.byType(TaskCheckbox));
      expect(received, isTrue);
    });

    testWidgets('calls onChanged(false) when checked and tapped', (tester) async {
      bool? received;
      await tester.pumpWidget(buildCheckbox(value: true, onChanged: (val) => received = val));
      await tester.tap(find.byType(TaskCheckbox));
      expect(received, isFalse);
    });

    testWidgets('shows checkmark text when checked', (tester) async {
      await tester.pumpWidget(buildCheckbox(value: true, onChanged: (_) {}));
      // Animate past the 0.5 threshold so the checkmark becomes visible
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('does not show checkmark when unchecked', (tester) async {
      await tester.pumpWidget(buildCheckbox(value: false, onChanged: (_) {}));
      await tester.pump();
      expect(find.text('✓'), findsNothing);
    });
  });
}
