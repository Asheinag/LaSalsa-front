import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart' as di;
import 'package:kabachok_lasalsa_front/core/api/task_service.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/api/recurring_task_service.dart';

void main() {
  group('Dependency Injection Container', () {
    setUp(() async {
      // Очищаем DI контейнер перед каждым тестом
      if (di.getIt.isRegistered<TaskService>()) {
        await di.getIt.unregister<TaskService>();
      }
      if (di.getIt.isRegistered<ProjectService>()) {
        await di.getIt.unregister<ProjectService>();
      }
      if (di.getIt.isRegistered<AiReviewService>()) {
        await di.getIt.unregister<AiReviewService>();
      }
      if (di.getIt.isRegistered<RecurringTaskService>()) {
        await di.getIt.unregister<RecurringTaskService>();
      }
    });

    test('init registers services', () async {
      // ACT
      await di.init();

      // ASSERT
      expect(di.getIt.isRegistered<TaskService>(), true);
      expect(di.getIt.isRegistered<ProjectService>(), true);
    });

    test('reset disposes and recreates services', () async {
      // ARRANGE
      await di.init();
      final taskService1 = di.getIt<TaskService>();
      final projectService1 = di.getIt<ProjectService>();

      // ACT
      await di.reset();

      // ASSERT - новые экземпляры должны быть созданы
      final taskService2 = di.getIt<TaskService>();
      final projectService2 = di.getIt<ProjectService>();

      expect(taskService2, isNot(same(taskService1)));
      expect(projectService2, isNot(same(projectService1)));
    });

    test('reset works when services are not initialized', () async {
      // ACT & ASSERT - не должно быть ошибки
      expect(() async => await di.reset(), returnsNormally);
    });

    test('services are lazy singletons', () async {
      // ARRANGE
      await di.init();

      // ACT
      final taskService1 = di.getIt<TaskService>();
      final taskService2 = di.getIt<TaskService>();

      // ASSERT - должен быть тот же экземпляр
      expect(taskService1, same(taskService2));
    });
  });
}
