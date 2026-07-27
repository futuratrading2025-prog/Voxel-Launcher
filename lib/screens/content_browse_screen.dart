import 'package:flutter/material.dart';
import '../services/modrinth_service.dart';
import '../services/version_manifest_service.dart';
import '../theme/app_theme.dart';

class ContentBrowseScreen extends StatefulWidget {
  final ContentType type;
  final String title;
  const ContentBrowseScreen({super.key, required this.type, required this.title});
  @override
  State<ContentBrowseScreen> createState() => _ContentBrowseScreenState();
}

class _ContentBrowseScreenState extends State<ContentBrowseScreen> {
  final _service = ModrinthService();
  final _searchCtrl = TextEditingController();
  List<ModrinthProject>? _results;

  Future<void> _search() async {
    setState(() => _results = null);
    final r = await _service.search(_searchCtrl.text, widget.type);
    setState(() => _results = r);
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索${widget.title}...',
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _results == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _results!.length,
                    itemBuilder: (_, i) {
                      final p = _results![i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: p.iconUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(p.iconUrl!, width: 40, height: 40, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.extension, color: AppTheme.primary),
                          title: Text(p.title, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(p.description,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          trailing: Text('${p.downloads}↓', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ContentVersionScreen(project: p, type: widget.type)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 选择要安装到的游戏版本，再选择该内容对应的文件版本并下载
class ContentVersionScreen extends StatefulWidget {
  final ModrinthProject project;
  final ContentType type;
  const ContentVersionScreen({super.key, required this.project, required this.type});
  @override
  State<ContentVersionScreen> createState() => _ContentVersionScreenState();
}

class _ContentVersionScreenState extends State<ContentVersionScreen> {
  final _modrinth = ModrinthService();
  final _versionService = VersionManifestService();
  List<String> _installedVersions = [];
  String? _selectedGameVersion;
  List<ModrinthFile>? _files;
  bool _downloading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadInstalled();
  }

  Future<void> _loadInstalled() async {
    final list = await _versionService.listInstalledVersions();
    setState(() => _installedVersions = list);
  }

  Future<void> _loadFiles() async {
    final f = await _modrinth.getVersions(widget.project.id, gameVersion: _selectedGameVersion);
    setState(() => _files = f);
  }

  Future<void> _download(ModrinthFile f) async {
    setState(() => _downloading = true);
    await _modrinth.download(f, widget.type, _selectedGameVersion!);
    setState(() {
      _downloading = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择要安装到的游戏版本', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            if (_installedVersions.isEmpty)
              const Text('还没有已安装的游戏版本，请先去"游戏版本安装"', style: TextStyle(color: Colors.redAccent, fontSize: 12))
            else
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedGameVersion,
                hint: const Text('选择版本', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppTheme.cardDark,
                items: _installedVersions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedGameVersion = v);
                  _loadFiles();
                },
              ),
            const SizedBox(height: 16),
            if (_done)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('安装成功', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
              ),
            if (_files != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _files!.length,
                  itemBuilder: (_, i) {
                    final f = _files![i];
                    return ListTile(
                      title: Text(f.versionNumber, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(f.fileName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      trailing: _downloading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(icon: const Icon(Icons.download), onPressed: () => _download(f)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
