import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/controls/game_control_overlay.dart';
import '../widgets/controls/virtual_joystick.dart';

/// 操控预览页：还没接游戏渲染画面前，用这个页面单独调操控手感。
/// 背景放一张游戏截图占位，叠加操控层，右上角实时显示当前事件方便调试。
class ControlPreviewScreen extends StatefulWidget {
  const ControlPreviewScreen({super.key});
  @override
  State<ControlPreviewScreen> createState() => _ControlPreviewScreenState();
}

class _ControlPreviewScreenState extends State<ControlPreviewScreen> {
  String _debugText = '（长按右上角齿轮图标进入编辑模式，可拖动按钮改位置）';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 占位游戏画面
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6EC1E4), Color(0xFF3A7D44)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(_debugText, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            ),
          ),
          GameControlOverlay(
            onMoveKeysChanged: (keys) => setState(() => _debugText = '移动: ${keys.map((k) => k.name).join('+')}'),
            onLook: (d) => setState(() => _debugText = '视角: dx=${d.dx.toStringAsFixed(1)} dy=${d.dy.toStringAsFixed(1)}'),
            onLeftClick: () => setState(() => _debugText = '左键：攻击/挖掘'),
            onRightClick: () => setState(() => _debugText = '右键：使用/放置'),
            onButtonEvent: (id, pressed) => setState(() => _debugText = '按钮 $id: ${pressed ? "按下" : "松开"}'),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
