import 'package:flutter/material.dart';
import '../services/version_manifest_service.dart';
import '../theme/app_theme.dart';

class GameVersionsScreen extends StatefulWidget {
  const GameVersionsScreen({super.key});
  @override
  State<GameVersionsScreen> createState() => _GameVersionsScreenState();
}

class _GameVersionsScreenState extends State<GameVersionsScreen> {
  final _service = VersionManifestService();
  List<GameVersion>? _versions;
  bool _onlyRelease = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.fetchVersionList();
    setState(() => _versions = list);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _versions?.where((v) => !_onlyRelease || v.type == 'release').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏版本安装'),
        actions: [
          Row(
            children: [
              const Text('仅正式版', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Switch(value: _onlyRelease, onChanged: (v) => setState(() => _onlyRelease = v)),
            ],
          ),
        ],
      ),
      body: filtered == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final v = filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(v.id, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(v.type, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VersionInstallScreen(version: v)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 点进具体版本后的安装页：一个"下载"按钮，点击后依次下载 json + client.jar
/// （均来自 Mojang 官方地址），完成后展示"安装成功"，下面提供"完成"按钮返回。
class VersionInstallScreen extends StatefulWidget {
  final GameVersion version;
  const VersionInstallScreen({super.key, required this.version});
  @override
  State<VersionInstallScreen> createState() => _VersionInstallScreenState();
}

class _VersionInstallScreenState extends State<VersionInstallScreen> {
  final _service = VersionManifestService();
  bool _installing = false;
  bool _done = false;
  double _progress = 0;
  String _stage = '';
  String? _error;

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      await _service.installVersion(
        widget.version,
        onProgress: (done, total, stage) {
          setState(() {
            _stage = stage;
            _progress = total > 0 ? done / total : 0;
          });
        },
      );
      setState(() {
        _installing = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _installing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.version.id)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_done ? Icons.check_circle : Icons.videogame_asset_rounded,
                size: 72, color: _done ? AppTheme.accent : AppTheme.primary),
            const SizedBox(height: 16),
            Text(widget.version.id, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_done)
              const Text('安装成功', style: TextStyle(color: AppTheme.accent, fontSize: 16)),
            if (_installing) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 8),
              Text(_stage, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
              ),
            const SizedBox(height: 32),
            if (!_installing && !_done)
              ElevatedButton.icon(
                onPressed: _install,
                icon: const Icon(Icons.download),
                label: const Text('下载'),
              ),
            if (_done)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成'),
              ),
          ],
        ),
      ),
    );
  }
}
