import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';

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
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 64, color: AppColors.borderLight),
            const SizedBox(height: 16),
            Text(
              'Выберите проект или задачу,\nчтобы увидеть детали',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
