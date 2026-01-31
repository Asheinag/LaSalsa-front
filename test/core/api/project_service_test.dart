import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/core/api/project_service.dart';
import 'package:kabachok_lasalsa_front/core/models/project.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'project_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late ProjectService projectService;

  setUp(() {
    mockDio = MockDio();
    projectService = ProjectService(dio: mockDio);
  });

  group('ProjectService Tests', () {
    group('getProjects', () {
      test('should return a list of projects on success', () async {
        // ARRANGE
        final projectsJson = [
          {'id': '1', 'name': 'Project 1', 'description': '', 'status': 'ACTIVE'},
          {'id': '2', 'name': 'Project 2', 'description': '', 'status': 'ACTIVE'},
        ];
        when(mockDio.get(any)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: projectsJson,
            statusCode: 200,
          ),
        );

        // ACT
        final result = await projectService.getProjects();

        // ASSERT
        expect(result, isA<List<Project>>());
        expect(result.length, 2);
        expect(result.first.name, 'Project 1');
        verify(mockDio.get('/')).called(1);
      });

      test('should throw an exception on network error', () async {
        // ARRANGE
        when(mockDio.get(any)).thenThrow(
          DioException(requestOptions: RequestOptions(path: '')),
        );

        // ACT & ASSERT
        expect(
          () => projectService.getProjects(),
          throwsA(
            predicate((e) =>
                e is Exception && e.toString() == 'Exception: Не удалось загрузить проекты.'),
          ),
        );
        verify(mockDio.get('/')).called(1);
      });
    });

    group('createProject', () {
      test('should return a new project on success', () async {
        // ARRANGE
        const projectName = 'New Project';
        final projectJson = {
          'id': '3',
          'name': projectName,
          'description': '',
          'status': 'ACTIVE',
        };
        when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: projectJson,
            statusCode: 201,
          ),
        );

        // ACT
        final result = await projectService.createProject(name: projectName);

        // ASSERT
        expect(result, isA<Project>());
        expect(result.name, projectName);
        expect(result.id, '3');
        verify(mockDio.post('/', data: {'name': projectName})).called(1);
      });

      test('should throw an exception on network error', () async {
        // ARRANGE
        when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
          DioException(requestOptions: RequestOptions(path: '')),
        );

        // ACT & ASSERT
        expect(
          () => projectService.createProject(name: 'Failed Project'),
          throwsA(
            predicate((e) =>
                e is Exception && e.toString() == 'Exception: Не удалось создать проект.'),
          ),
        );
        verify(mockDio.post('/', data: {'name': 'Failed Project'})).called(1);
      });
    });
  });
}
