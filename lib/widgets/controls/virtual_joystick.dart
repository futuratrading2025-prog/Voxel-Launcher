import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 虚拟摇杆（左手移动）
///
/// 输出 [-1,1] 范围的 dx/dy，上层负责把它换算成 WASD 按键状态：
/// dy < -0.3 → W, dy > 0.3 → S, dx < -0.3 → A, dx > 0.3 → D
/// （斜方向可以同时触发两个键，和真实键盘一致）
class VirtualJoystick extends StatefulWidget {
  final double size;
  final ValueChanged<Offset> onChanged; // 归一化后的 dx, dy
  final VoidCallback? onReleased;

  const VirtualJoystick({
    super.key,
    this.size = 120,
    required this.onChanged,
    this.onReleased,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobOffset = Offset.zero;
  final double _knobRatio = 0.42; // 摇杆头相对底盘半径

  void _updateFromLocal(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = local - center;
    final maxRadius = widget.size / 2;
    final distance = delta.distance;
    final clamped = distance > maxRadius ? delta / distance * maxRadius : delta;
    setState(() => _knobOffset = clamped);
    widget.onChanged(Offset(clamped.dx / maxRadius, clamped.dy / maxRadius));
  }

  void _reset() {
    setState(() => _knobOffset = Offset.zero);
    widget.onChanged(Offset.zero);
    widget.onReleased?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _updateFromLocal(d.localPosition),
      onPanUpdate: (d) => _updateFromLocal(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.28),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Align(
          alignment: Alignment(
            _knobOffset.dx / (widget.size / 2),
            _knobOffset.dy / (widget.size / 2),
          ),
          child: Container(
            width: widget.size * _knobRatio,
            height: widget.size * _knobRatio,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withOpacity(0.85),
              boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

/// 把摇杆的 dx/dy 转换成移动按键集合，方便上层直接判断该按住哪些键
class JoystickKeys {
  static Set<MoveKey> fromOffset(Offset o, {double deadzone = 0.25}) {
    final keys = <MoveKey>{};
    if (o.distance < deadzone) return keys;
    if (o.dy < -deadzone) keys.add(MoveKey.forward);
    if (o.dy > deadzone) keys.add(MoveKey.back);
    if (o.dx < -deadzone) keys.add(MoveKey.left);
    if (o.dx > deadzone) keys.add(MoveKey.right);
    return keys;
  }
}

enum MoveKey { forward, back, left, right }
