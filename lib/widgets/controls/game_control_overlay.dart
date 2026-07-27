import 'package:flutter/material.dart';
import '../../models/control_layout.dart';
import '../../theme/app_theme.dart';
import 'control_button.dart';
import 'look_pad.dart';
import 'virtual_joystick.dart';

/// 覆盖在游戏画面上的完整触屏操控层。
///
/// 用法：把这个 Widget 用 Stack 叠在游戏渲染画面（未来接入 JVM 渲染纹理）
/// 之上即可。当前 [onMoveKeysChanged] / [onLook] / [onLeftClick] 等回调
/// 先接一个调试用的状态展示；未来接入运行时后，把这些回调换成真正给
/// JVM 发送按键/鼠标事件的桥接方法即可，UI 层完全不用改。
class GameControlOverlay extends StatefulWidget {
  final ValueChanged<Set<MoveKey>>? onMoveKeysChanged;
  final ValueChanged<Offset>? onLook;
  final VoidCallback? onLeftClick;
  final VoidCallback? onRightClick;
  final void Function(String buttonId, bool pressed)? onButtonEvent;

  const GameControlOverlay({
    super.key,
    this.onMoveKeysChanged,
    this.onLook,
    this.onLeftClick,
    this.onRightClick,
    this.onButtonEvent,
  });

  @override
  State<GameControlOverlay> createState() => _GameControlOverlayState();
}

class _GameControlOverlayState extends State<GameControlOverlay> {
  List<ControlButtonSpec> _specs = ControlLayout.defaultLayout();
  bool _editMode = false;
  bool _sprintLocked = false;

  static const _iconMap = {
    'jump': Icons.arrow_upward_rounded,
    'sneak': Icons.arrow_downward_rounded,
    'sprint': Icons.directions_run_rounded,
    'inventory': Icons.inventory_2_rounded,
    'drop': Icons.file_download_outlined,
    'pause': Icons.pause_rounded,
  };
  static const _labelMap = {
    'jump': '跳跃',
    'sneak': '潜行',
    'sprint': '疾跑',
    'inventory': '背包',
    'drop': '丢弃',
    'pause': '菜单',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final specs = await ControlLayout.load();
    setState(() => _specs = specs);
  }

  void _dragSpec(ControlButtonSpec spec, Offset localDelta, Size screenSize) {
    setState(() {
      spec.xRatio = (spec.xRatio + localDelta.dx / screenSize.width).clamp(0.02, 0.98);
      spec.yRatio = (spec.yRatio + localDelta.dy / screenSize.height).clamp(0.02, 0.98);
    });
  }

  void _handleButton(String id, bool pressed) {
    if (id == 'sprint' && !pressed) {
      // 疾跑按一下切换锁定状态，而不是必须一直按住（更符合手机操作习惯）
      setState(() => _sprintLocked = !_sprintLocked);
    }
    widget.onButtonEvent?.call(id, pressed);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 视角拖动区：铺满屏幕右侧 60%，避免和左侧摇杆冲突
            if (!_editMode)
              Positioned(
                left: screenSize.width * 0.38,
                top: 0,
                right: 0,
                bottom: 0,
                child: LookPad(
                  onLookDelta: (d) => widget.onLook?.call(d),
                  onLeftClick: widget.onLeftClick,
                  onRightClick: widget.onRightClick,
                ),
              ),

            // 左手虚拟摇杆
            Positioned(
              left: 24,
              bottom: 32,
              child: VirtualJoystick(
                onChanged: (o) => widget.onMoveKeysChanged?.call(JoystickKeys.fromOffset(o)),
              ),
            ),

            // 可自定义位置的功能按钮
            for (final spec in _specs.where((s) => s.visible))
              Positioned(
                left: spec.xRatio * screenSize.width - 28,
                top: spec.yRatio * screenSize.height - 28,
                child: _editMode
                    ? GestureDetector(
                        onPanUpdate: (d) => _dragSpec(spec, d.delta, screenSize),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.5),
                            border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid),
                          ),
                          child: Icon(_iconMap[spec.id], color: Colors.white),
                        ),
                      )
                    : ControlButton(
                        icon: _iconMap[spec.id]!,
                        label: _labelMap[spec.id],
                        holdMode: spec.id != 'sprint' && spec.id != 'pause',
                        toggled: spec.id == 'sprint' && _sprintLocked,
                        onHoldChanged: (p) => _handleButton(spec.id, p),
                        onTap: () => _handleButton(spec.id, true),
                      ),
              ),

            // 编辑模式开关（右上角小图标，长按 1.5 秒切换，避免误触）
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onLongPress: () => setState(() => _editMode = !_editMode),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _editMode ? AppTheme.accent.withOpacity(0.85) : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_editMode ? Icons.check : Icons.tune, color: Colors.white, size: 18),
                ),
              ),
            ),
            if (_editMode)
              Positioned(
                right: 12,
                top: 52,
                child: Row(
                  children: [
                    _EditModeChip(
                      label: '保存',
                      onTap: () async {
                        await ControlLayout.save(_specs);
                        if (mounted) setState(() => _editMode = false);
                      },
                    ),
                    const SizedBox(width: 6),
                    _EditModeChip(
                      label: '重置',
                      onTap: () async {
                        await ControlLayout.reset();
                        await _load();
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EditModeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _EditModeChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ),
    );
  }
}
