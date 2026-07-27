import 'package:flutter/material.dart';

/// 视角拖动区（右手区域，通常铺满屏幕右半边甚至整个游戏画面上层）
///
/// - 手指拖动 → 输出 delta，上层换算成鼠标移动（转视角）
/// - 短按抬起 → 触发一次"左键"（挖方块/攻击）
/// - 双指点按或长按 → 触发一次"右键"（放置/使用）
/// 这是 PojavLauncher 等主流方案的标准手势映射，玩家上手成本最低。
class LookPad extends StatefulWidget {
  final ValueChanged<Offset> onLookDelta;
  final VoidCallback? onLeftClick; // 攻击/挖掘
  final VoidCallback? onRightClick; // 使用/放置
  final double sensitivity;

  const LookPad({
    super.key,
    required this.onLookDelta,
    this.onLeftClick,
    this.onRightClick,
    this.sensitivity = 1.0,
  });

  @override
  State<LookPad> createState() => _LookPadState();
}

class _LookPadState extends State<LookPad> {
  Offset? _lastPos;
  double _totalMoveDistance = 0;
  DateTime? _downTime;

  void _onPointerDown(PointerDownEvent e) {
    _lastPos = e.localPosition;
    _totalMoveDistance = 0;
    _downTime = DateTime.now();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_lastPos == null) return;
    final delta = e.localPosition - _lastPos!;
    _totalMoveDistance += delta.distance;
    widget.onLookDelta(delta * widget.sensitivity);
    _lastPos = e.localPosition;
  }

  void _onPointerUp(PointerUpEvent e) {
    // 移动距离很小、按住时间不长 → 判定为"点击"而非"拖动看视角"
    final duration = DateTime.now().difference(_downTime ?? DateTime.now());
    if (_totalMoveDistance < 12) {
      if (duration.inMilliseconds > 350) {
        widget.onRightClick?.call();
      } else {
        widget.onLeftClick?.call();
      }
    }
    _lastPos = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      behavior: HitTestBehavior.translucent,
      child: Container(color: Colors.transparent),
    );
  }
}
