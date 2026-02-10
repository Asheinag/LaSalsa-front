import 'package:dio/dio.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/api/config.dart';
import 'package:kabachok_lasalsa_front/core/api/auth_interceptor.dart';

class ProjectService {
  final Dio _dio;
  static final String _url = '$apiBaseUrl/projects';

  ProjectService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _url)) {
    if (dio == null) {
      _dio.interceptors.add(AuthInterceptor());
    }
  }

  Future<List<Project>> getProjects() async {
    try {
      final response = await _dio.get('/');
      final List<dynamic> jsonData = response.data;
      return jsonData
          .map((projectJson) => Project.fromJson(projectJson))
          .toList();
    } on DioException catch (e) {
      logger.e('Ошибка Dio при загрузке проектов: ${e.response?.statusCode}');
      throw Exception('Не удалось загрузить проекты.');
    } catch (e) {
      logger.e('Неизвестная ошибка при загрузке проектов: $e');
      throw Exception('Произошла непредвиденная ошибка.');
    }
  }

  Future<Project> createProject({required String name, String? colorId}) async {
    try {
      final Map<String, dynamic> data = {'name': name};
      if (colorId != null) {
        data['color_id'] = colorId;
      }
      final response = await _dio.post('/', data: data);
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      logger.e('Ошибка Dio при создании проекта: ${e.response?.statusCode}');
      throw Exception('Не удалось создать проект.');
    }
  }

  Future<void> deleteProject({required String projectId}) async {
    try {
      await _dio.delete('/$projectId');
    } on DioException catch (e) {
      logger.e('Ошибка Dio при удалении проекта: ${e.response?.statusCode}');
      throw Exception('Не удалось удалить проект.');
    }
  }

  Future<void> updateProject({
    required String projectId,
    String? name,
    String? description,
    String? colorId,
    DateTime? deadline,
    String? status,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) {
        data['name'] = name;
      }
      if (description != null) {
        data['description'] = description;
      }
      if (colorId != null) {
        data['color_id'] = colorId;
      }
      if (deadline != null) {
        data['deadline'] = deadline.toIso8601String();
      }
      if (type != null) {
        data['type'] = type;
      }
      if (status != null) {
        data['status'] = status;
      }
      await _dio.patch('/$projectId', data: data);
    } on DioException catch (e) {
      logger.e('Ошибка Dio при обновлении проекта: ${e.response?.statusCode}');
      throw Exception('Не удалось обновить проект.');
    }
  }
}
