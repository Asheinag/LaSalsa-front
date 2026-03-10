import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';

class AiScoreBadge extends StatefulWidget {
  final int? score;

  const AiScoreBadge({super.key, this.score});

  @override
  State<AiScoreBadge> createState() => _AiScoreBadgeState();
}

class _AiScoreBadgeState extends State<AiScoreBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.score == null) return const SizedBox.shrink();

    final score = widget.score!;
    final Color bg;
    final Color color;

    if (score >= 8) {
      bg = AppColors.greenLight;
      color = AppColors.green;
    } else if (score >= 6) {
      bg = AppColors.tomatoLight;
      color = AppColors.tomato;
    } else {
      bg = AppColors.accentLight;
      color = AppColors.accent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
