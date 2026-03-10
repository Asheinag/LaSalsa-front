import 'package:flutter_test/flutter_test.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';

void main() {
  // ─── AIReviewComment ────────────────────────────────────────────────────────

  group('AIReviewComment.fromJson', () {
    test('парсит корректный JSON', () {
      final json = {
        'verdict': 'Задача размыта',
        'score': 7,
        'questions': ['Нет глагола', 'Нет срока'],
      };

      final comment = AIReviewComment.fromJson(json);

      expect(comment.verdict, 'Задача размыта');
      expect(comment.score, 7);
      expect(comment.questions, ['Нет глагола', 'Нет срока']);
    });

    test('подставляет дефолты при отсутствующих полях', () {
      final comment = AIReviewComment.fromJson({});

      expect(comment.verdict, '');
      expect(comment.score, 0);
      expect(comment.questions, isEmpty);
    });

    test('парсит score из double', () {
      final comment = AIReviewComment.fromJson({'score': 8.5});

      expect(comment.score, 8);
    });
  });

  // ─── AIReviewShort ──────────────────────────────────────────────────────────

  group('AIReviewShort.fromJson', () {
    test('парсит задачный ревью', () {
      final json = {
        'id': 'r1',
        'is_active': true,
        'task_id': 't1',
        'project_id': null,
      };

      final short = AIReviewShort.fromJson(json);

      expect(short.id, 'r1');
      expect(short.isActive, true);
      expect(short.taskId, 't1');
      expect(short.projectId, isNull);
    });

    test('парсит проектный ревью', () {
      final json = {
        'id': 'r2',
        'is_active': false,
        'task_id': null,
        'project_id': 'p1',
      };

      final short = AIReviewShort.fromJson(json);

      expect(short.projectId, 'p1');
      expect(short.isActive, false);
    });

    test('is_active дефолт false при отсутствии', () {
      final short = AIReviewShort.fromJson({'id': 'r1'});

      expect(short.isActive, false);
    });

    test('id конвертируется из числа', () {
      final short = AIReviewShort.fromJson({'id': 42});

      expect(short.id, '42');
    });
  });

  // ─── AIReviewRead ───────────────────────────────────────────────────────────

  group('AIReviewRead.fromJson', () {
    test('парсит полный JSON', () {
      final json = {
        'id': 'r1',
        'is_active': true,
        'created_at': '2024-02-25T14:32:00Z',
        'task_id': 't1',
        'project_id': null,
        'comment': {
          'verdict': 'Задача размыта',
          'score': 7,
          'questions': ['Нет глагола'],
        },
      };

      final review = AIReviewRead.fromJson(json);

      expect(review.id, 'r1');
      expect(review.isActive, true);
      expect(review.taskId, 't1');
      expect(review.projectId, isNull);
      expect(review.comment.verdict, 'Задача размыта');
      expect(review.comment.score, 7);
      expect(review.createdAt, DateTime.utc(2024, 2, 25, 14, 32));
    });

    test('подставляет пустой comment если comment не Map', () {
      final json = {
        'id': 'r1',
        'is_active': false,
        'created_at': '2024-02-25T14:32:00Z',
        'comment': 'не объект',
      };

      final review = AIReviewRead.fromJson(json);

      expect(review.comment.verdict, '');
      expect(review.comment.score, 0);
      expect(review.comment.questions, isEmpty);
    });

    test('подставляет пустой comment если comment null', () {
      final json = {
        'id': 'r1',
        'is_active': false,
        'created_at': '2024-02-25T14:32:00Z',
        'comment': null,
      };

      final review = AIReviewRead.fromJson(json);

      expect(review.comment.score, 0);
    });
  });
}
