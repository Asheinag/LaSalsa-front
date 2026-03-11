import 'package:flutter/material.dart';

class ProjectColorData {
  final Color light;
  final Color dark;

  const ProjectColorData(this.light, this.dark);

  static const List<ProjectColorData> palette = [
    ProjectColorData(Colors.grey, Colors.grey),
    ProjectColorData(Color(0xFFFFCDD2), Color(0xFFB71C1C)),
    ProjectColorData(
      Color(0xFFC8E6C9),
      Color(0xFF1B5E20),
    ), // Light Green / Dark Green
    ProjectColorData(
      Color(0xFFBBDEFB),
      Color(0xFF0D47A1),
    ), // Light Blue / Dark Blue
    ProjectColorData(
      Color(0xFFFFF9C4),
      Color(0xFFF57F17),
    ), // Light Yellow / Dark Yellow
    ProjectColorData(
      Color(0xFFD1C4E9),
      Color(0xFF4A148C),
    ), // Light Purple / Dark Purple
  ];

  static Color getColor(BuildContext context, int index) {
    final safeIndex = (index < 0 || index >= palette.length) ? 0 : index;
    final colorData = palette[safeIndex];

    // Проверяем тему устройства
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? colorData.dark : colorData.light;
  }
}
