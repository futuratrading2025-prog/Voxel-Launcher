import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 单个操控按钮，支持普通点击（如"跳跃"按一下）
/// 和按住不放（如"潜行"按住蹲下松开站起）两种模式，
/// 通过 [holdMode] 区分。
class ControlButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final bool holdMode;
  final ValueChanged<bool>? onHoldChanged; // holdMode: true=按下, false=松开
  final VoidCallback? onTap; // !holdMode
  final double size;
  final bool toggled; // 用于"疾跑锁定"这类开关态按钮的高亮显示

  const ControlButton({
    super.key,
    required this.icon,
    this.label,
    this.holdMode = true,
    this.onHoldChanged,
    this.onTap,
    this.size = 56,
    this.toggled = false,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _pressed || widget.toggled;
    return GestureDetector(
      onTapDown: widget.holdMode
          ? (_) {
              setState(() => _pressed = true);
              widget.onHoldChanged?.call(true);
            }
          : null,
      onTapUp: widget.holdMode
          ? (_) {
              setState(() => _pressed = false);
              widget.onHoldChanged?.call(false);
            }
          : null,
      onTapCancel: widget.holdMode
          ? () {
              setState(() => _pressed = false);
              widget.onHoldChanged?.call(false);
            }
          : null,
      onTap: widget.holdMode ? null : widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppTheme.accent.withOpacity(0.85) : Colors.black.withOpacity(0.32),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: widget.size * 0.42),
            if (widget.label != null)
              Text(widget.label!, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
