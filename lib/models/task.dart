class Task {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime? plannedAt;
  final DateTime? closedAt;

  Task({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.plannedAt,
    this.closedAt,
  });

  Task copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    DateTime? plannedAt,
    DateTime? closedAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      plannedAt: plannedAt ?? this.plannedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'TODO',
      plannedAt: json['planned_at'] != null
          ? DateTime.parse(json['planned_at'])
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'status': status,
      // Если дата не null, преобразуем ее в строку нужного формата
      'planned_at': plannedAt?.toIso8601String(),
    };
  }
}
