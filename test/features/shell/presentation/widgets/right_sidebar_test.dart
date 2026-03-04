import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/right_sidebar.dart';

void main() {
  group('RightSidebar Tests', () {
    testWidgets('starts collapsed by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RightSidebar(child: Text('Inspector content')),
          ),
        ),
      );

      final panelWidth = tester.getSize(find.byType(AnimatedContainer)).width;
      expect(panelWidth, 0.0);
    });

    testWidgets('expands when strip is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RightSidebar(child: Text('Inspector content')),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      final panelWidth = tester.getSize(find.byType(AnimatedContainer)).width;
      expect(panelWidth, greaterThan(0));
    });

    testWidgets('collapses when strip is tapped while expanded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RightSidebar(child: Text('Inspector content')),
          ),
        ),
      );

      // First tap: expand
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).width, greaterThan(0));

      // Second tap: collapse
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).width, 0.0);
    });

    testWidgets('auto-expands when selectionKey changes from null to a value', (tester) async {
      String? selectionKey;
      late StateSetter stateSetter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                stateSetter = setState;
                return RightSidebar(
                  selectionKey: selectionKey,
                  child: const Text('Inspector content'),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(AnimatedContainer)).width, 0.0);

      stateSetter(() => selectionKey = 'task-123');
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AnimatedContainer)).width, greaterThan(0));
    });

    testWidgets('auto-expands when selectionKey changes from one task to another', (tester) async {
      String? selectionKey = 'task-1';
      late StateSetter stateSetter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                stateSetter = setState;
                return RightSidebar(
                  selectionKey: selectionKey,
                  child: const Text('Inspector content'),
                );
              },
            ),
          ),
        ),
      );

      // Collapse manually
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).width, greaterThan(0));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).width, 0.0);

      // Change to different task — should auto-expand again
      stateSetter(() => selectionKey = 'task-2');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AnimatedContainer)).width, greaterThan(0));
    });

    testWidgets('shows empty state text when no child provided and expanded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RightSidebar()),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Выбери задачу\nчтобы открыть инспектор'), findsOneWidget);
    });
  });
}
