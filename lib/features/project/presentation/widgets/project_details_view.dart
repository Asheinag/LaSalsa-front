// import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kabachok_lasalsa_front/core/models/task.dart';
// import 'package:kabachok_lasalsa_front/core/models/project.dart';
// import 'package:kabachok_lasalsa_front/core/theme/project_colors.dart';
// import 'package:kabachok_lasalsa_front/core/api/task_service.dart';

class ProjectDetailsView extends StatefulWidget {
  const ProjectDetailsView({super.key});

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Проект выбран',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
