import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_placeholder.dart';

void main() {
  Widget buildPlaceholder({String buttonLabel = 'Проверить', VoidCallback? onPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: AiReviewPlaceholder(buttonLabel: buttonLabel, onPressed: onPressed),
      ),
    );
  }

  group('AiReviewPlaceholder', () {
    testWidgets('renders ✦ symbol', (tester) async {
      await tester.pumpWidget(buildPlaceholder());
      expect(find.text('✦'), findsOneWidget);
    });

    testWidgets('renders "Ментор ещё не проверял" text', (tester) async {
      await tester.pumpWidget(buildPlaceholder());
      expect(find.text('Ментор ещё не проверял'), findsOneWidget);
    });

    testWidgets('renders button with provided label', (tester) async {
      await tester.pumpWidget(buildPlaceholder(buttonLabel: 'Запустить проверку'));
      expect(find.text('Запустить проверку'), findsOneWidget);
    });

    testWidgets('calls onPressed when button is tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildPlaceholder(onPressed: () => pressed = true));
      await tester.tap(find.text('Проверить'));
      expect(pressed, isTrue);
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildPlaceholder());
      expect(find.byType(AiReviewPlaceholder), findsOneWidget);
    });
  });
}
