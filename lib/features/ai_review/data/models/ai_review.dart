class AIReviewComment {
  final String verdict;
  final int score;
  final List<String> questions;

  const AIReviewComment({
    required this.verdict,
    required this.score,
    required this.questions,
  });

  factory AIReviewComment.fromJson(Map<String, dynamic> json) {
    return AIReviewComment(
      verdict: json['verdict'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => q.toString())
              .toList() ??
          [],
    );
  }
}

class AIReviewShort {
  final String id;
  final bool isActive;
  final String? taskId;
  final String? projectId;

  const AIReviewShort({
    required this.id,
    required this.isActive,
    this.taskId,
    this.projectId,
  });

  factory AIReviewShort.fromJson(Map<String, dynamic> json) {
    return AIReviewShort(
      id: json['id'].toString(),
      isActive: json['is_active'] as bool? ?? false,
      taskId: json['task_id']?.toString(),
      projectId: json['project_id']?.toString(),
    );
  }
}

class AIReviewRead {
  final String id;
  final bool isActive;
  final DateTime createdAt;
  final String? taskId;
  final String? projectId;
  final AIReviewComment comment;

  const AIReviewRead({
    required this.id,
    required this.isActive,
    required this.createdAt,
    required this.comment,
    this.taskId,
    this.projectId,
  });

  factory AIReviewRead.fromJson(Map<String, dynamic> json) {
    final rawComment = json['comment'];
    final AIReviewComment comment;
    if (rawComment is Map<String, dynamic>) {
      comment = AIReviewComment.fromJson(rawComment);
    } else {
      comment = const AIReviewComment(verdict: '', score: 0, questions: []);
    }

    return AIReviewRead(
      id: json['id'].toString(),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskId: json['task_id']?.toString(),
      projectId: json['project_id']?.toString(),
      comment: comment,
    );
  }
}
