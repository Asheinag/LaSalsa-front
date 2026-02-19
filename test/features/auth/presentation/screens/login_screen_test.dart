import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen', () {
    setUp(() {
      // Устанавливаем размер экрана для тестов
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('displays email and password fields', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
    });

    testWidgets('displays login and signup buttons', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Зарегистрироваться'), findsOneWidget);
    });

    testWidgets('email field has correct autofill hints', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      expect(emailField.autofillHints, contains(AutofillHints.email));
      expect(emailField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('password field has correct autofill hints', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Пароль'),
      );
      expect(passwordField.autofillHints, contains(AutofillHints.password));
      expect(passwordField.obscureText, true);
    });

    testWidgets('fields are wrapped in AutofillGroup', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      expect(find.byType(AutofillGroup), findsOneWidget);
    });

    testWidgets('email field has next text input action', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      expect(emailField.textInputAction, TextInputAction.next);
    });

    testWidgets('password field has done text input action', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Пароль'),
      );
      expect(passwordField.textInputAction, TextInputAction.done);
    });

    testWidgets('displays logo image', (tester) async {
      // ARRANGE
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // ACT
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // ASSERT
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
