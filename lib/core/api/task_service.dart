import 'package:dio/dio.dart';
import 'package:kabachok_lasalsa_front/core/models/task.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/api/config.dart';
import 'package:kabachok_lasalsa_front/core/api/auth_interceptor.dart';

class TaskService {
  final Dio _dio;
  static final String _url = apiBaseUrl;

  TaskService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _url)) {
    if (dio == null) {
      _dio.interceptors.add(AuthInterceptor());
    }
  }

  // Получаем список задач на сегодня
  Future<List<Task>> getTodayTasks({
    required String offset,
    required String limit,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final response = await _dio.get(
        '/tasks/today?offset=$offset&limit=$limit',
      );
      final List<dynamic> jsonData = response.data;
      return jsonData.map((taskJson) => Task.fromJson(taskJson)).toList();
    } on DioException catch (e) {
      logger.e(
        'Ошибка Dio при загрузке задач на сегодня: ${e.response?.statusCode}',
      );
      throw Exception('Не удалось загрузить задачи на сегодня.');
    }
  }

  // Отправляем изменение статуса задачи
  Future<Task> updateTaskStatus({
    required String taskId,
    required String taskStatus,
  }) async {
    try {
      final response = await _dio.patch(
        '/tasks/$taskId',
        data: {'status': taskStatus},
      );
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      logger.e(
        'Ошибка Dio при обновлении статуса задачи: ${e.response?.statusCode}',
      );
      throw Exception('Не удалось обновить статус задачи.');
    }
  }

  Future<List<Task>> getTasks({
    required String offset,
    required String limit,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final response = await _dio.get('/tasks');
      final List<dynamic> jsonData = response.data;

      return jsonData.map((taskJson) => Task.fromJson(taskJson)).toList();
    } on DioException catch (e) {
      logger.e('Ошибка Dio при загрузке задач: ${e.response?.statusCode}');
      throw Exception('Не удалось загрузить задачи.');
    }
  }

  // Создаем новую задачу
  Future<Task> createTask({
    required String taskName, // Обязательный параметр
    String? description, // Опционально
    DateTime? plannedAt, // Опционально (дата выполнения)
    String? projectId, // Опционально (привязка к проекту)
    String? parentId,
  }) async {
    try {
      // 1. Собираем базовые данные
      final Map<String, dynamic> requestData = {
        'name': taskName,
        // Если описание не передали, шлем пустую строку (как было у тебя)
        'description': description ?? '',
      };

      // 2. Добавляем опциональные поля, ТОЛЬКО если они не null
      if (projectId != null) {
        requestData['project_id'] =
            projectId; // Проверь: на бэке camelCase или snake_case?
      }

      if (parentId != null) {
        requestData['parent_id'] = parentId;
      }

      if (plannedAt != null) {
        // Даты всегда нужно превращать в строку для отправки по сети
        requestData['planned_at'] = plannedAt.toIso8601String();
      }

      // 3. Отправляем запрос
      final response = await _dio.post('/tasks', data: requestData);

      return Task.fromJson(response.data);
    } on DioException catch (e) {
      logger.e('Ошибка Dio при создании задачи: ${e.response?.statusCode}');
      throw Exception('Не удалось создать задачу.');
    }
  }

  // Поучаем задачи по проекту
  Future<List<Task>> getTasksByProject({required String projectId}) async {
    try {
      logger.i('Загружаем задачи для проекта ID: $projectId');
      final response = await _dio.get('/projects/$projectId/tasks');
      final List<dynamic> jsonData = response.data;

      return jsonData.map((taskJson) => Task.fromJson(taskJson)).toList();
    } on DioException catch (e) {
      logger.e(
        'Ошибка Dio при загрузке задач проекта: ${e.response?.statusCode}',
      );
      throw Exception('Не удалось загрузить задачи проекта.');
    }
  }

  // Обновляем задачу
  Future<Task> updateTask({
    required String taskId,
    String? name,
    String? description,
    String? status,
    DateTime? plannedAt,
    String? projectId,
    String? parentId,
    String? colorId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {};

      if (name != null) requestData['name'] = name;
      if (description != null) requestData['description'] = description;
      if (status != null) requestData['status'] = status;
      if (colorId != null) requestData['color_id'] = colorId;
      if (plannedAt != null) {
        requestData['planned_at'] = plannedAt.toIso8601String();
      }
      if (projectId != null) requestData['project_id'] = projectId;
      if (parentId != null) requestData['parent_id'] = parentId;

      final response = await _dio.patch('/tasks/$taskId', data: requestData);

      return Task.fromJson(response.data);
    } on DioException catch (e) {
      logger.e('Ошибка Dio при обновлении задачи: ${e.response?.statusCode}');
      throw Exception('Не удалось обновить задачу.');
    }
  }

  // Получаем детали задачи
  Future<Task> getTaskDetails({required String taskId}) async {
    try {
      final response = await _dio.get('/tasks/$taskId');
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      logger.e(
        'Ошибка Dio при получении деталей задачи: ${e.response?.statusCode}',
      );
      throw Exception('Не удалось получить детали задачи.');
    }
  }

  // Удаляем задачу
  Future<void> deleteTask({required String taskId}) async {
    try {
      await _dio.delete('/tasks/$taskId');
    } on DioException catch (e) {
      logger.e('Ошибка Dio при удалении задачи: ${e.response?.statusCode}');
      throw Exception('Не удалось удалить задачу.');
    }
  }
}
