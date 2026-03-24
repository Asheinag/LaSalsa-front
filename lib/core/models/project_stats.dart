class ProjectStats {
  final int total;
  final int active;
  final int completed;

  const ProjectStats({
    required this.total,
    required this.active,
    required this.completed,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      total: (json['total'] as num).toInt(),
      active: (json['active'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
    );
  }
}
