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
        '/tasks/status',
        data: {'id': taskId, 'status': taskStatus},
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
      final response = await _dio.get('/tasks?offset=$offset&limit=$limit');
      final List<dynamic> jsonData = response.data;

      return jsonData.map((taskJson) => Task.fromJson(taskJson)).toList();
    } on DioException catch (e) {
      logger.e('Ошибка Dio при загрузке задач: ${e.response?.statusCode}');
      throw Exception('Не удалось загрузить задачи.');
    }
  }

  // Создаем новую задачу
  Future<Task> createTask({required String taskName}) async {
    try {
      final response = await _dio.post(
        '/tasks',
        data: {'name': taskName, 'description': ''},
      );
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
}
