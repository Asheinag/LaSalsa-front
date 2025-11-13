import 'package:dio/dio.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:kabachok_lasalsa_front/core/utils/logger.dart';
import 'package:kabachok_lasalsa_front/core/api/config.dart';
import 'package:kabachok_lasalsa_front/core/api/auth_interceptor.dart';

class ProjectService {
  final Dio _dio;
  static final String _url = '$apiBaseUrl/projects';

  // Настраиваем Dio с базовым URL  и перехватчиком
  ProjectService() : _dio = Dio(BaseOptions(baseUrl: _url)) {
    _dio.interceptors.add(AuthInterceptor());
  }

  // Получаем список проектов для текущего пользователя
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

  // Создаем новый проект
  Future<Project> createProject({required String name}) async {
    try {
      final response = await _dio.post(
        '/',
        data: {'name': name},
      );
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      logger.e('Ошибка Dio при создании проекта: ${e.response?.statusCode}');
      throw Exception('Не удалось создать проект.');
    }
  }
}
