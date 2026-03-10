import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kabachok_lasalsa_front/core/api/ai_review_service.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/data/models/ai_review.dart';
import 'package:kabachok_lasalsa_front/features/ai_review/presentation/widgets/ai_review_card.dart';
import 'package:kabachok_lasalsa_front/injection_container.dart';

class AiReviewHistoryModal extends StatefulWidget {
  final String? taskId;
  final String? projectId;

  const AiReviewHistoryModal({super.key, this.taskId, this.projectId})
      : assert(taskId != null || projectId != null,
            'Нужен taskId или projectId');

  @override
  State<AiReviewHistoryModal> createState() => _AiReviewHistoryModalState();
}

class _AiReviewHistoryModalState extends State<AiReviewHistoryModal> {
  final AiReviewService _service = getIt<AiReviewService>();
  List<AIReviewShort>? _history;
  AIReviewRead? _detail;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final List<AIReviewShort> items;
    if (widget.taskId != null) {
      items = await _service.getTaskReviewHistory(widget.taskId!);
    } else {
      items = await _service.getProjectReviewHistory(widget.projectId!);
    }
    if (mounted) setState(() => _history = items);
  }

  Future<void> _openDetail(String reviewId) async {
    setState(() => _loadingDetail = true);
    try {
      final review = await _service.getReviewById(reviewId);
      if (mounted) setState(() { _detail = review; _loadingDetail = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        if (_detail != null)
          GestureDetector(
            onTap: () => setState(() => _detail = null),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('Назад', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent)),
                ],
              ),
            ),
          )
        else
          Text('История ревью', style: AppTextStyles.inspectorTitle),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_detail != null) {
      final dateStr = DateFormat('d MMM, HH:mm').format(_detail!.createdAt.toLocal());
      return AiReviewCard(
        verdict: _detail!.comment.verdict,
        score: _detail!.comment.score,
        issues: _detail!.comment.questions,
        suggestion: _detail!.comment.questions.isNotEmpty
            ? _detail!.comment.questions.last
            : '',
        date: dateStr,
      );
    }

    if (_loadingDetail) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_history == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_history!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'История пуста',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _history!.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
        itemBuilder: (_, i) => _HistoryItem(
          item: _history![i],
          onTap: () => _openDetail(_history![i].id),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final AIReviewShort item;
  final VoidCallback onTap;

  const _HistoryItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // id может содержать дату в формате UUID — дату не парсим, показываем порядковый номер
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.id,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (item.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Актуальный',
                    style: AppTextStyles.tagLabel.copyWith(color: AppColors.accent),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
