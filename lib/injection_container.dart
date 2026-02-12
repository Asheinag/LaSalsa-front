import 'package:get_it/get_it.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // --- Services ---

  // registerLazySingleton: Сервис создастся только тогда,
  // когда кто-то ПЕРВЫЙ раз его попросит.

  getIt.registerLazySingleton(() => TaskService());
  getIt.registerLazySingleton(() => ProjectService());

  // В будущем сюда добавишь:
  // sl.registerLazySingleton(() => AuthService());
  // sl.registerLazySingleton(() => Dio()); // Чтобы и Dio был общим
}
