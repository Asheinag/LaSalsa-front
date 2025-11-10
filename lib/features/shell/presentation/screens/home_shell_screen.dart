import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late Widget _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = const TodayScreen();
  }

  void _selectScreen(Widget screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Левая колонка: наш сайдбар
          AppSidebar(onScreenSelected: _selectScreen),

          // Разделитель вертикальный
          const VerticalDivider(width: 1, thickness: 1),

          // Правая колонка: активная рабочая область, которая будет изменяться
          Expanded(
            child: _currentScreen, // <--  Здесь отображается активный экран
          ),
        ],
      ),
    );
  }
}
