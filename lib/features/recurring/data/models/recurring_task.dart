enum RecurringFrequency { daily, weekly, monthly, interval }

class RecurringTask {
  final int id;
  final String name;
  final String? description;
  final int? projectId;
  final int? taskId;
  final RecurringFrequency frequency;
  final List<int> days;
  final String timezone;
  final bool isActive;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;

  const RecurringTask({
    required this.id,
    required this.name,
    this.description,
    this.projectId,
    this.taskId,
    required this.frequency,
    required this.days,
    required this.timezone,
    required this.isActive,
    required this.nextRunAt,
    this.lastRunAt,
  });

  factory RecurringTask.fromJson(Map<String, dynamic> json) {
    return RecurringTask(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      projectId: json['project_id'] as int?,
      taskId: json['task_id'] as int?,
      frequency: _parseFrequency(json['frequency'] as String),
      days: (json['days'] as List<dynamic>).cast<int>(),
      timezone: json['timezone'] as String? ?? 'UTC',
      isActive: json['is_active'] as bool? ?? true,
      nextRunAt: DateTime.parse(json['next_run_at'] as String),
      lastRunAt: json['last_run_at'] != null
          ? DateTime.parse(json['last_run_at'] as String)
          : null,
    );
  }

  static RecurringFrequency _parseFrequency(String value) {
    switch (value) {
      case 'daily':
        return RecurringFrequency.daily;
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'monthly':
        return RecurringFrequency.monthly;
      case 'interval':
        return RecurringFrequency.interval;
      default:
        return RecurringFrequency.daily;
    }
  }
}

String formatRecurrence(RecurringTask r) {
  switch (r.frequency) {
    case RecurringFrequency.daily:
      return 'Каждый день';
    case RecurringFrequency.weekly:
      const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      if (r.days.isEmpty) return 'Каждый день';
      return r.days.map((d) => dayNames[d.clamp(0, 6)]).join(', ');
    case RecurringFrequency.monthly:
      if (r.days.isEmpty) return 'По числам';
      if (r.days.length == 1) return '${r.days.first}-го числа';
      final parts = r.days.map((d) => '$d-го').toList();
      return '${parts.take(parts.length - 1).join(', ')} и ${parts.last} числа';
    case RecurringFrequency.interval:
      final n = r.days.isNotEmpty ? r.days.first : 1;
      if (n == 1) return 'Каждый день';
      if (n % 10 == 1 && n % 100 != 11) return 'Каждый $n день';
      if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
        return 'Каждые $n дня';
      }
      return 'Каждые $n дней';
  }
}
