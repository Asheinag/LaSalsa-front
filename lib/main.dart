import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/navigation/auth_gate.dart';
import 'core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно для async main

  await initializeDateFormatting(
    'ru_RU',
    null,
  ); // Инициализация локализации дат

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await di.init(); // Инициализация DI

  runApp(const LaSalsaApp());
}

class LaSalsaApp extends StatelessWidget {
  const LaSalsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaSalsa – Задачи',
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
