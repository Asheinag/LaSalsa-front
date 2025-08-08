import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kabachok_lasalsa_front/api/task_api.dart';
import 'package:kabachok_lasalsa_front/models/task.dart';
import 'package:kabachok_lasalsa_front/widgets/task_card.dart';

import 'package:mockito/mockito.dart';

// Создаём мок для TaskApi
class MockTaskApi extends Mock implements TaskApi {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized(); // обязательно
  await initializeDateFormatting('ru_RU', null);
  // Пример задачи
  final sampleTask = Task(
    id: '1',
    name: 'Тестовая задача',
    status: 'TODO',
    description: 'Описание тестовой задачи',
    plannedAt: DateTime.now().add(const Duration(days: 3)),
    closedAt: null,
  );

  testWidgets('TaskCard отображает имя задачи и реагирует на нажатие', (
    WidgetTester tester,
  ) async {
    // Создаем моковый API
    final mockApi = MockTaskApi();

    // Переменная для проверки обновления
    bool tapped = false;

    // Создаем TaskCard внутри MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: sampleTask,
            taskApi: mockApi,
            onTaskUpdated: (_) {},
            onStatusToggle: (val) {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Проверка текста задачи
    expect(find.text('Тестовая задача'), findsOneWidget);

    // Нажатие на кнопку статуса
    final statusButton = find.byIcon(Icons.radio_button_unchecked);
    expect(statusButton, findsOneWidget);
    await tester.tap(statusButton);
    await tester.pumpAndSettle();

    // Проверка, что callback отработал
    expect(tapped, isTrue);
  });
}
