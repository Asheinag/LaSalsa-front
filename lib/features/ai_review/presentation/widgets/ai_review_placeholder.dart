import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';

class AiReviewPlaceholder extends StatelessWidget {
  final String buttonLabel;
  final VoidCallback? onPressed;

  const AiReviewPlaceholder({
    super.key,
    required this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✦',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Ментор ещё не проверял',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _AiButton(label: buttonLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _AiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const _AiButton({required this.label, this.onPressed});

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFF5D5D0)
                : AppColors.accentLight,
            border: Border.all(color: const Color(0xFFE8B5B0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.accent,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
