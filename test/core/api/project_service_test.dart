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
          {
            'id': '1',
            'name': 'Project 1',
            'description': '',
            'status': 'ACTIVE',
          },
          {
            'id': '2',
            'name': 'Project 2',
            'description': '',
            'status': 'ACTIVE',
          },
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
        verify(mockDio.get('/?offset=0&limit=50')).called(1);
      });

      test('should throw an exception on network error', () async {
        // ARRANGE
        when(
          mockDio.get(any),
        ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

        // ACT & ASSERT
        expect(
          () => projectService.getProjects(),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString() == 'Exception: Не удалось загрузить проекты.',
            ),
          ),
        );
        verify(mockDio.get('/?offset=0&limit=50')).called(1);
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
        when(
          mockDio.post(any, data: anyNamed('data')),
        ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

        // ACT & ASSERT
        expect(
          () => projectService.createProject(name: 'Failed Project'),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString() == 'Exception: Не удалось создать проект.',
            ),
          ),
        );
        verify(mockDio.post('/', data: {'name': 'Failed Project'})).called(1);
      });
    });
  });

  group('ProjectService Stream Tests', () {
    test('updateProject should emit updated project to stream', () async {
      // ARRANGE
      final fakeResponse = {
        "id": "1",
        "name": "Updated Project",
        "color_id": "2",
      };

      when(mockDio.patch(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse,
          statusCode: 200,
        ),
      );

      // ASSERT
      // Ожидаем, что стрим эмитит объект Project
      expectLater(projectService.projectUpdates, emits(isA<Project>()));

      // ACT
      await projectService.updateProject(
        projectId: '1',
        name: 'Updated Project',
      );
    });

    test('createProject should emit new project to stream', () async {
      // ARRANGE
      final fakeResponse = {"id": "2", "name": "New Project", "color_id": "1"};

      when(mockDio.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: fakeResponse,
          statusCode: 201,
        ),
      );

      // ASSERT
      expectLater(projectService.projectUpdates, emits(isA<Project>()));

      // ACT
      await projectService.createProject(name: 'New Project');
    });

    test('deleteProject should emit deleted project ID to stream', () async {
      // ARRANGE
      when(mockDio.delete(any)).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: ''), statusCode: 204),
      );

      // ASSERT
      expectLater(projectService.projectDeletions, emits('1'));

      // ACT
      await projectService.deleteProject(projectId: '1');
    });
  });
}
