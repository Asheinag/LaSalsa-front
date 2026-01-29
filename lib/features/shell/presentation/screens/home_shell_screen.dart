import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:kabachok_lasalsa_front/features/tasks/presentation/widgets/task_inspector.dart';
// Импортируй свои экраны
import 'package:kabachok_lasalsa_front/features/today/presentation/screens/today_screen.dart';
import 'package:kabachok_lasalsa_front/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:kabachok_lasalsa_front/features/project/presentation/screens/project_details_scren.dart';
// Дебаг
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  // 1. Храним не сам виджет экрана, а "Идентификатор" того, что выбрано
  // (В идеале это enum, но пока пусть будет String или int index)
  String _selectedPageId = 'today';

  // Храним аргументы (например, выбранный проект)
  dynamic _currentPageArgs;

  // 2. Храним выбранную задачу для третьей колонки
  Task? _selectedTask;

  // Обработчик переключения страниц (приходит из Sidebar)
  void _onPageChanged(String pageId, {dynamic args}) {
    setState(() {
      _selectedPageId = pageId;
      _currentPageArgs = args;
      _selectedTask = null; // Сбрасываем выбранную задачу при смене раздела
    });
    logger.i('Переключение на страницу: $pageId с аргументами: $args');
  }

  // Метод обработки клика по задаче (вызывается из TodayScreen и др)
  void _handleTaskTap(Task task) {
    setState(() {
      _selectedTask = task;
    });
  }

  // Фабрика экранов
  Widget _buildActiveScreen() {
    switch (_selectedPageId) {
      case 'today':
        logger.i('Построение экрана TodayScreen');
        return TodayScreen(
          onTaskTap: _handleTaskTap, // Подключаем тап!
        );

      case 'inbox':
        logger.i('Построение экрана InboxScreen');
        return InboxScreen(
          onTaskTap: _handleTaskTap, // Подключаем тап!
        );

      case 'project':
        logger.i('Построение экрана ProjectDetailsScreen');
        // Достаем проект из аргументов
        if (_currentPageArgs is Project) {
          return ProjectDetailsScreen(
            project: _currentPageArgs as Project,
            onTaskTap: _handleTaskTap, // Подключаем тап!
          );
        }
        return const Center(child: Text("Ошибка: Проект не выбран"));

      default:
        return const Center(child: Text("404"));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Определяем ширину экрана
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      body: Row(
        children: [
          // 1. Сайдбар
          AppSidebar(
            // Передаем нашу новую функцию
            onPageSelected: _onPageChanged,
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // 2. Основной контент
          Expanded(flex: 5, child: _buildActiveScreen()),

          // --------------------------
          // 3. ПРАВАЯ КОЛОНКА (Инспектор)
          // --------------------------
          if (isDesktop) ...[
            // Показываем только на широком экране
            const VerticalDivider(width: 1, thickness: 1),

            Expanded(
              flex: 2, // Занимает 3 части ширины (чуть уже списка)
              child: TaskInspector(
                task: _selectedTask,
                onClose: () => setState(() => _selectedTask = null),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
