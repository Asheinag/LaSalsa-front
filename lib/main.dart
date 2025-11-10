import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/navigation/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно для async main
  await initializeDateFormatting(
    'ru_RU',
    null,
  ); // Инициализация локализации дат
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LaSalsaApp());
}

class LaSalsaApp extends StatelessWidget {
  const LaSalsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaSalsa – Задачи',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 43, 78, 233),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
