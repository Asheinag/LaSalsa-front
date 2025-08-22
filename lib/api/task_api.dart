import 'package:dio/dio.dart';

import '../models/task.dart';
import '../utils/logger.dart';
import '../config.dart';
import 'auth_interceptor.dart';

class TaskApi {
  final Dio _dio;

  static final String _url = '$apiBaseUrl/tasks';

  TaskApi() : _dio = Dio(BaseOptions(baseUrl: _url)) {
    // Вот где происходит магия: мы добавляем наш перехватчик
    _dio.interceptors.add(AuthInterceptor());
  }

  Future<List<Task>> fetchTasks() async {
    try {
      // Внутри try мы пишем только "счастливый" сценарий
      final response = await _dio.get('/');

      // Если мы дошли до этой строки, значит статус ответа УЖЕ успешный (2xx).
      // Нет нужды в if (response.statusCode == 200)

      final List<dynamic> jsonData = response.data;
      return jsonData.map((taskJson) => Task.fromJson(taskJson)).toList();
    } on DioException catch (e) {
      // Если сервер вернул ошибку (4xx, 5xx), мы попадем сюда
      logger.e('Ошибка Dio при загрузке задач: ${e.response?.statusCode}');

      // Мы можем обработать ошибку или выбросить свое, более понятное исключение
      throw Exception('Не удалось загрузить задачи.');
    }
  }

  Future<Task> addTask(Task task) async {
    final response = await _dio.post('/', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<Task> getTaskDetails(String taskId) async {
    final response = await _dio.get('/$taskId');

    return Task.fromJson(response.data);
  }

  Future<void> setTaskStatus(String taskId, String taskStatus) async {
    try {
      await _dio.patch('/status', data: {'status': taskStatus, 'id': taskId});
    } on DioException catch (e) {
      logger.e('Не удалось обновить задачу: ${e.response?.statusCode}');
      throw Exception('Не удалось обновить задачу.');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _dio.delete('/', data: {'id': taskId});
    } on DioException catch (e) {
      logger.e('Ошибка при удалении задачи: ${e.response?.statusCode}');
      throw Exception('Не удалось удалить задачу.');
    }
  }

  Future<Task> updateTask(Task updatedTask, String taskId) async {
    try {
      final response = await _dio.put(
        '/$taskId/update',
        data: updatedTask.toJson(),
      );
      logger.d('Обновлена задача $taskId');
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      logger.e('Не удалось обновить задачу: ${e.response?.statusCode}');
      throw Exception('Не удалось удалить задачу.');
    }
  }
}
