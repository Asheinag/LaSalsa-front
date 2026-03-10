import 'package:dio/dio.dart';
import 'package:kabachok_lasalsa_front/core/api/auth_interceptor.dart';
import 'package:kabachok_lasalsa_front/core/api/config.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';

class AiReviewService {
  final Dio _dio;
  static final String _url = '$apiBaseUrl/ai-reviews';

  AiReviewService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _url)) {
    if (dio == null) {
      _dio.interceptors.add(AuthInterceptor());
    }
  }

  // ─── Task reviews ─────────────────────────────────────────────────────────

  Future<AIReviewRead?> getActiveTaskReview(String taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/active');
      return AIReviewRead.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      logger.e('Ошибка при загрузке ревью задачи: ${e.response?.statusCode}');
      return null;
    }
  }

  Future<List<AIReviewShort>> getTaskReviewHistory(String taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/history');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => AIReviewShort.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      logger.e('Ошибка при загрузке истории ревью задачи: ${e.response?.statusCode}');
      return [];
    }
  }

  Future<String> runTaskReview(String taskId) async {
    final response = await _dio.post('/tasks/$taskId/run');
    return (response.data['celery_task_id'] as String?) ?? (response.data['task_id'] as String);
  }

  // ─── Project reviews ──────────────────────────────────────────────────────

  Future<AIReviewRead?> getActiveProjectReview(String projectId) async {
    try {
      final response = await _dio.get('/projects/$projectId/active');
      return AIReviewRead.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      logger.e('Ошибка при загрузке ревью проекта: ${e.response?.statusCode}');
      return null;
    }
  }

  Future<List<AIReviewShort>> getProjectReviewHistory(String projectId) async {
    try {
      final response = await _dio.get('/projects/$projectId/history');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => AIReviewShort.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      logger.e('Ошибка при загрузке истории ревью проекта: ${e.response?.statusCode}');
      return [];
    }
  }

  Future<String> runProjectReview(String projectId) async {
    final response = await _dio.post('/projects/$projectId/run');
    return (response.data['celery_task_id'] as String?) ?? (response.data['task_id'] as String);
  }

  // ─── Shared ───────────────────────────────────────────────────────────────

  Future<AIReviewRead> getReviewById(String reviewId) async {
    final response = await _dio.get('/$reviewId');
    return AIReviewRead.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> getReviewStatus(String celeryTaskId) async {
    try {
      final response = await _dio.get('/status/$celeryTaskId');
      return (response.data['status'] as String?) ?? 'error';
    } on DioException catch (e) {
      logger.e('Ошибка при проверке статуса ревью: ${e.response?.statusCode}');
      return 'error';
    }
  }
}
