import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 单个按钮在屏幕上的相对位置（0~1 比例，适配不同屏幕尺寸）与功能类型
class ControlButtonSpec {
  final String id; // jump / sneak / sprint / inventory / drop / chat / pause
  double xRatio;
  double yRatio;
  bool visible;

  ControlButtonSpec({
    required this.id,
    required this.xRatio,
    required this.yRatio,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {'id': id, 'x': xRatio, 'y': yRatio, 'v': visible};
  factory ControlButtonSpec.fromJson(Map<String, dynamic> j) =>
      ControlButtonSpec(id: j['id'], xRatio: j['x'], yRatio: j['y'], visible: j['v'] ?? true);
}

/// 默认布局：参考 PojavLauncher 的常见摆法——
/// 右下角一圈功能键，跳跃靠右手拇指最顺手的位置
class ControlLayout {
  static List<ControlButtonSpec> defaultLayout() => [
        ControlButtonSpec(id: 'jump', xRatio: 0.90, yRatio: 0.72),
        ControlButtonSpec(id: 'sneak', xRatio: 0.78, yRatio: 0.85),
        ControlButtonSpec(id: 'sprint', xRatio: 0.90, yRatio: 0.85),
        ControlButtonSpec(id: 'inventory', xRatio: 0.92, yRatio: 0.10),
        ControlButtonSpec(id: 'drop', xRatio: 0.80, yRatio: 0.10),
        ControlButtonSpec(id: 'pause', xRatio: 0.06, yRatio: 0.06),
      ];

  static const _prefKey = 'control_layout_v1';

  static Future<List<ControlButtonSpec>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return defaultLayout();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ControlButtonSpec.fromJson(e)).toList();
    } catch (_) {
      return defaultLayout();
    }
  }

  static Future<void> save(List<ControlButtonSpec> specs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(specs.map((e) => e.toJson()).toList()));
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
