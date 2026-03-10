import 'package:get_it/get_it.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // --- Services ---

  // registerLazySingleton: Сервис создастся только тогда,
  // когда кто-то ПЕРВЫЙ раз его попросит.

  getIt.registerLazySingleton(() => TaskService());
  getIt.registerLazySingleton(() => ProjectService());
  getIt.registerLazySingleton(() => AiReviewService());

  // В будущем сюда добавишь:
  // sl.registerLazySingleton(() => AuthService());
  // sl.registerLazySingleton(() => Dio()); // Чтобы и Dio был общим
}

/// Сбрасывает все сервисы и очищает кэш
/// Используется при выходе пользователя из системы
Future<void> reset() async {
  // Вызываем dispose на существующих сервисах, если они были созданы
  if (getIt.isRegistered<TaskService>()) {
    final taskService = getIt<TaskService>();
    taskService.dispose();
    await getIt.unregister<TaskService>();
  }

  if (getIt.isRegistered<ProjectService>()) {
    final projectService = getIt<ProjectService>();
    projectService.dispose();
    await getIt.unregister<ProjectService>();
  }

  if (getIt.isRegistered<AiReviewService>()) {
    await getIt.unregister<AiReviewService>();
  }

  // Пересоздаем сервисы заново
  getIt.registerLazySingleton(() => TaskService());
  getIt.registerLazySingleton(() => ProjectService());
  getIt.registerLazySingleton(() => AiReviewService());
}
