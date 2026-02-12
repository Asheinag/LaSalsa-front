import 'package:flutter/material.dart';

/// В будущем это будет
class BasicDetailView extends StatefulWidget {
  const BasicDetailView({super.key});

  @override
  State<BasicDetailView> createState() => _BasicDetailViewState();
}

class _BasicDetailViewState extends State<BasicDetailView> {
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
              'Выберите проект или задачу,\nчтобы увидеть детали',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
