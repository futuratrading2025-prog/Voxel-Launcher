import 'package:flutter/material.dart';
import '../services/msa_auth_service.dart';
import '../services/version_manifest_service.dart';
import '../theme/app_theme.dart';
import 'control_preview_screen.dart';

/// 启动游戏页：展示已安装的版本卡片，点击"启动"。
///
/// ⚠️ 技术提醒（写在这里方便你后续开发时看到）：
/// 手机上"启动"Minecraft Java 版和 PC 不一样 —— Java 版本体是要跑在 JVM
/// 上的桌面程序，Android 不能直接运行 .jar。业内方案（如 PojavLauncher/
/// Zalith Launcher）是内置移植版 JRE + 用 Zink/VirGL 做 OpenGL→Vulkan/GLES
/// 转换在容器里跑起来，工程量很大，不是几个 Dart 文件能解决的，通常需要
/// 接入现成的开源运行时组件（原生 Android/NDK 层）。这部分建议作为独立
/// 模块规划，这里先把"下载安装+账号体系+资源管理+操控UI"这套框架搭好。
class LaunchScreen extends StatefulWidget {
  final MinecraftAccount account;
  const LaunchScreen({super.key, required this.account});
  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final _service = VersionManifestService();
  List<String> _versions = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await _service.listInstalledVersions();
    setState(() => _versions = list);
  }

  void _launch(String versionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('启动 $versionId —— 需接入 JVM 运行时模块（见代码注释）')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.gamepad_outlined, color: AppTheme.primary),
              title: const Text('触屏操控预览 / 编辑', style: TextStyle(color: Colors.white)),
              subtitle: const Text('调整摇杆、按钮位置和手感', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ControlPreviewScreen())),
            ),
          ),
          if (_versions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(Icons.videogame_asset_off, size: 56, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  const Text('还没有已安装的游戏版本', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  const Text('去"下载"页安装一个版本吧', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else
            for (final v in _versions)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.videogame_asset_rounded, color: AppTheme.accent),
                  title: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('账号：${widget.account.username}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () => _launch(v),
                    child: const Text('启动'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
