import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';

class AiReviewCard extends StatefulWidget {
  final String verdict;
  final int score;
  final List<String> issues;
  final String suggestion;
  final String date;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;

  const AiReviewCard({
    super.key,
    required this.verdict,
    required this.score,
    required this.issues,
    required this.suggestion,
    required this.date,
    this.onTap,
    this.onHistoryTap,
  });

  @override
  State<AiReviewCard> createState() => _AiReviewCardState();
}

class _AiReviewCardState extends State<AiReviewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovered ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered
                ? const [
                    BoxShadow(
                      color: Color(0x172A1F14),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHead(),
              _buildBody(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Шапка ───────────────────────────────────────────────────────────────

  Widget _buildHead() {
    final pill = _ScorePill(score: widget.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.accentLight,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8B5B0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '✦ AI МЕНТОР',
            style: AppTextStyles.tagLabel.copyWith(
              color: AppColors.accent,
              letterSpacing: 0.5,
            ),
          ),
          pill,
        ],
      ),
    );
  }

  // ─── Тело ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict
          Text(
            widget.verdict,
            style: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          // Issues
          if (widget.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...widget.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.accent,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        issue,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Suggestion
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '→ ${widget.suggestion}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.green,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Футер ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(widget.date, style: AppTextStyles.metaText)),
          GestureDetector(
            onTap: widget.onHistoryTap,
            child: MouseRegion(
              cursor: widget.onHistoryTap != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Text(
                'История →',
                style: AppTextStyles.metaText.copyWith(
                  color: AppColors.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accent,
                  decorationStyle: TextDecorationStyle.solid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score pill ───────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color color;
    final BoxDecoration decoration;

    if (score >= 8) {
      bg = AppColors.greenLight;
      color = AppColors.green;
      decoration = BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20));
    } else if (score >= 6) {
      bg = AppColors.tomatoLight;
      color = AppColors.tomato;
      decoration = BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20));
    } else {
      bg = AppColors.accentLight;
      color = AppColors.accent;
      decoration = BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8B5B0)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: decoration,
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
