import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';

class TaskDueDate extends StatelessWidget {
  final DateTime? plannedAt;

  const TaskDueDate({super.key, this.plannedAt});

  @override
  Widget build(BuildContext context) {
    if (plannedAt == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(plannedAt!.year, plannedAt!.month, plannedAt!.day);
    final diff = date.difference(today).inDays;

    final String label;
    final Color color;
    final FontWeight weight;

    if (diff == 0) {
      label = 'сегодня';
      color = AppColors.tomato;
      weight = FontWeight.w500;
    } else if (diff == 1) {
      label = 'завтра';
      color = AppColors.jalap;
      weight = FontWeight.w500;
    } else if (diff < 0) {
      final d = plannedAt!;
      label = '${d.day} ${_monthShort(d.month)}';
      color = AppColors.accent;
      weight = FontWeight.w500;
    } else {
      final d = plannedAt!;
      label = '${_weekdayShort(d.weekday)}, ${d.day} ${_monthShort(d.month)}';
      color = AppColors.textMuted;
      weight = FontWeight.normal;
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: weight,
      ),
    );
  }

  static String _monthShort(int month) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return months[month - 1];
  }

  static String _weekdayShort(int weekday) {
    const days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return days[weekday - 1];
  }
}
