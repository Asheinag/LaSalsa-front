import 'package:dio/dio.dart';
import 'package:kabachok_lasalsa_front/core/api/auth_interceptor.dart';
import 'package:kabachok_lasalsa_front/core/api/config.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/recurring/data/models/recurring_task.dart';

class RecurringTaskService {
  final Dio _dio;
  static final String _url = '$apiBaseUrl/recurring-tasks';

  RecurringTaskService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _url)) {
    if (dio == null) {
      _dio.interceptors.add(AuthInterceptor());
    }
  }

  Future<RecurringTask?> getByTaskId(String taskId) async {
    try {
      final response = await _dio.get('/by-task/$taskId');
      return RecurringTask.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      logger.e('Ошибка при загрузке шаблона повторения: ${e.response?.statusCode}');
      return null;
    }
  }

  Future<RecurringTask> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/', data: data);
      return RecurringTask.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      logger.e('Ошибка при создании шаблона повторения: ${e.response?.statusCode}');
      throw Exception('Не удалось создать расписание.');
    }
  }

  Future<RecurringTask> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/$id', data: data);
      return RecurringTask.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      logger.e('Ошибка при обновлении шаблона повторения: ${e.response?.statusCode}');
      throw Exception('Не удалось обновить расписание.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/$id');
    } on DioException catch (e) {
      logger.e('Ошибка при удалении шаблона повторения: ${e.response?.statusCode}');
      throw Exception('Не удалось удалить расписание.');
    }
  }
}
