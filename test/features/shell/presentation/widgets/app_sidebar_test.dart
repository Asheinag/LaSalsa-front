import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';

@GenerateMocks([ProjectService])
import 'app_sidebar_test.mocks.dart';

void main() {
  late MockProjectService mockProjectService;

  setUp(() {
    mockProjectService = MockProjectService();
  });

  testWidgets('AppSidebar creates project with selected color', (tester) async {
    // ARRANGE
    when(
      mockProjectService.createProject(
        name: anyNamed('name'),
        colorId: anyNamed('colorId'),
      ),
    ).thenAnswer(
      (_) async =>
          Project(id: '1', name: 'New Project', status: 'ACTIVE', colorId: '2'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSidebar(
            projects: [],
            onPageSelected: (page, {args}) {},
            onProjectCreated: (newProject) {},
            projectService: mockProjectService,
          ),
        ),
      ),
    );

    // ACT
    await tester.tap(find.text('Создать проект'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'My New Project');

    // Submit
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // VERIFY
    verify(
      mockProjectService.createProject(name: 'My New Project', colorId: '0'),
    ).called(1);
  });
}
