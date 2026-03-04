import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_card.dart';

void main() {
  Widget buildCard({
    String verdict = 'Задача сформулирована размыто',
    int score = 6,
    List<String> issues = const ['Нет конкретного глагола действия'],
    String suggestion = 'Переформулируй: начни с глагола',
    String date = '25 фев, 14:32',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AiReviewCard(
          verdict: verdict,
          score: score,
          issues: issues,
          suggestion: suggestion,
          date: date,
        ),
      ),
    );
  }

  group('AiReviewCard', () {
    testWidgets('renders AI МЕНТОР label in header', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('✦ AI МЕНТОР'), findsOneWidget);
    });

    testWidgets('renders score in pill', (tester) async {
      await tester.pumpWidget(buildCard(score: 7));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('renders verdict text', (tester) async {
      await tester.pumpWidget(buildCard(verdict: 'Задача сформулирована размыто'));
      expect(find.text('Задача сформулирована размыто'), findsOneWidget);
    });

    testWidgets('renders issues list', (tester) async {
      await tester.pumpWidget(buildCard(issues: ['Проблема 1', 'Проблема 2']));
      expect(find.text('Проблема 1'), findsOneWidget);
      expect(find.text('Проблема 2'), findsOneWidget);
    });

    testWidgets('hides issues block when issues list is empty', (tester) async {
      await tester.pumpWidget(buildCard(issues: []));
      expect(find.text('·'), findsNothing);
    });

    testWidgets('renders suggestion with arrow prefix', (tester) async {
      await tester.pumpWidget(buildCard(suggestion: 'Декомпозируй задачи'));
      expect(find.textContaining('Декомпозируй задачи'), findsOneWidget);
    });

    testWidgets('renders date in footer', (tester) async {
      await tester.pumpWidget(buildCard(date: '25 фев, 14:32'));
      expect(find.text('25 фев, 14:32'), findsOneWidget);
    });

    testWidgets('renders "История →" link in footer', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('История →'), findsOneWidget);
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.byType(AiReviewCard), findsOneWidget);
    });
  });
}
