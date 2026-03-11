import 'package:flutter/material.dart';
import 'package:kabachok_lasalsa_front/core/theme/app_colors.dart';

class TaskCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TaskCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<TaskCheckbox>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      value: widget.value ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant TaskCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;
            final bg = Color.lerp(Colors.transparent, AppColors.green, t)!;
            final borderColor = t > 0.5
                ? AppColors.green
                : (_isHovered ? AppColors.accent : AppColors.border);

            return Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: t > 0.5
                  ? Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: ((t - 0.5) * 2).clamp(0.0, 1.0)),
                        height: 1,
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
