import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/widgets/task_input_field.dart';

void main() {
  testWidgets('TaskInputField triggers onAdd when add button pressed', (tester) async {
    final controller = TextEditingController();
    String? addedText;
    DateTime? addedDate;

    await tester.pumpWidget(MaterialApp(
      home: TaskInputField(
        controller: controller,
        onAdd: (text, date) {
          addedText = text;
          addedDate = date;
        },
        onSelectDate: () {},
      ),
    ));

    await tester.enterText(find.byType(TextField), ' new task ');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(addedText, 'new task');
    expect(addedDate, isNull);
  });

  testWidgets('TaskInputField triggers onAdd on submit', (tester) async {
    final controller = TextEditingController();
    String? addedText;

    await tester.pumpWidget(MaterialApp(
      home: TaskInputField(
        controller: controller,
        onAdd: (text, date) {
          addedText = text;
        },
        onSelectDate: () {},
      ),
    ));

    await tester.enterText(find.byType(TextField), 'submit task');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(addedText, 'submit task');
  });

  testWidgets('TaskInputField displays selected date and reacts to calendar tap', (tester) async {
    final controller = TextEditingController();
    bool tapped = false;
    final date = DateTime(2024, 1, 2);

    await tester.pumpWidget(MaterialApp(
      home: TaskInputField(
        controller: controller,
        onAdd: (_, __) {},
        selectedDate: date,
        onSelectDate: () {
          tapped = true;
        },
      ),
    ));

    expect(find.text('2024-01-02'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
