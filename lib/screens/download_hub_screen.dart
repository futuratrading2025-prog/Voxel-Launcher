import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/modrinth_service.dart';
import '../services/import_service.dart';
import 'game_versions_screen.dart';
import 'content_browse_screen.dart';
import 'import_screen.dart';

/// 下载中心 —— 类似 PCL 的"下载"页：
/// 上半区：游戏版本 / 光影 / 模组 / 整合包 四个在线安装入口
/// 下半区：整合包导入 / 模组导入 / 光影包导入 三个本地文件导入入口
class DownloadHubScreen extends StatelessWidget {
  const DownloadHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('在线安装'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _DownloadTile(
              icon: Icons.videogame_asset_rounded,
              label: '游戏版本安装',
              subtitle: '官方 Mojang 版本清单',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameVersionsScreen())),
            ),
            _DownloadTile(
              icon: Icons.wb_sunny_rounded,
              label: '光影安装',
              subtitle: 'Modrinth 光影库',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ContentBrowseScreen(type: ContentType.shader, title: '光影安装'))),
            ),
            _DownloadTile(
              icon: Icons.extension_rounded,
              label: '模组安装',
              subtitle: 'Modrinth 模组库',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ContentBrowseScreen(type: ContentType.mod, title: '模组安装'))),
            ),
            _DownloadTile(
              icon: Icons.inventory_2_rounded,
              label: '整合包安装',
              subtitle: 'Modrinth 整合包库',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContentBrowseScreen(type: ContentType.modpack, title: '整合包安装'))),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('本地导入'),
        _ImportTile(
          icon: Icons.inventory_2_outlined,
          label: '整合包导入',
          hint: '选择 .mrpack 整合包文件',
          kind: ImportKind.modpack,
        ),
        _ImportTile(
          icon: Icons.extension_outlined,
          label: '模组导入',
          hint: '选择 .jar 模组文件',
          kind: ImportKind.mod,
        ),
        _ImportTile(
          icon: Icons.wb_sunny_outlined,
          label: '光影包导入',
          hint: '选择 .zip 光影包文件',
          kind: ImportKind.shader,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

class _DownloadTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _DownloadTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.accent, size: 28),
              const Spacer(),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  final IconData icon;
  final String label, hint;
  final ImportKind kind;
  const _ImportTile({required this.icon, required this.label, required this.hint, required this.kind});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        subtitle: Text(hint, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImportScreen(kind: kind))),
      ),
    );
  }
}
