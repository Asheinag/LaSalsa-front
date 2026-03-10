import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_text_styles.dart';

class RightSidebar extends StatefulWidget {
  final Widget? child;
  /// Меняется при каждой смене выбранного элемента (id задачи или проекта).
  /// null = ничего не выбрано.
  final String? selectionKey;

  const RightSidebar({super.key, this.child, this.selectionKey});

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant RightSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Авто-разворачиваем при любой смене выбранного элемента
    if (widget.selectionKey != null &&
        widget.selectionKey != oldWidget.selectionKey) {
      setState(() => _isExpanded = true);
    }
  }

  static const double _panelWidth = 348;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStrip(),
        _buildPanel(),
      ],
    );
  }

  // ─── Полоска (всегда видима, 28px) ──────────────────────────────────────────

  Widget _buildStrip() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 28,
          decoration: const BoxDecoration(
            color: AppColors.bgPanel,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Стрелка вверху
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: AnimatedRotation(
                  turns: _isExpanded ? 0 : 0.5,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              // Вертикальный текст "Инспектор" (исчезает когда открыто)
              AnimatedOpacity(
                opacity: _isExpanded ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'ИНСПЕКТОР',
                    style: AppTextStyles.sidebarLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Панель инспектора (348px ↔ 0px) ────────────────────────────────────────

  Widget _buildPanel() {
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.ease,
        width: _isExpanded ? _panelWidth : 0,
        decoration: const BoxDecoration(
          color: AppColors.bgPanel,
          border: Border(left: BorderSide(color: AppColors.borderLight)),
        ),
        child: SizedBox(
          width: _panelWidth,
          child: widget.child ?? _buildEmptyState(),
        ),
      ),
    );
  }

  // ─── Пустое состояние ───────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('☝️', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            'Выбери задачу\nчтобы открыть инспектор',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
