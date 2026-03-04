class Project {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? parentId;
  final String type;
  final DateTime? updatedAt;
  final DateTime? deadline;
  final String? colorId;

  Project({
    required this.id,
    required this.name,
    required this.status,
    this.description,
    this.parentId,
    this.updatedAt,
    this.deadline,
    this.type = 'LIST',
    this.colorId = '0',
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? status,
    String? parentId,
    String? type,
    DateTime? updatedAt,
    DateTime? deadline,
    String? colorId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      parentId: parentId ?? this.parentId,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      type: type ?? this.type,
      colorId: colorId ?? this.colorId,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
      type: (json['type'] as String? ?? 'LIST').toUpperCase(),
      parentId: json['parent_id']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      colorId: json['color_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'status': status,
      'type': type,
      if (parentId != null) 'parent_id': parentId,
      'deadline': deadline?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (colorId != null) 'color_id': colorId,
    };
  }
}
