import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/import_service.dart';
import '../services/version_manifest_service.dart';
import '../theme/app_theme.dart';

class ImportScreen extends StatefulWidget {
  final ImportKind kind;
  const ImportScreen({super.key, required this.kind});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _importService = ImportService();
  final _versionService = VersionManifestService();

  List<String> _installedVersions = [];
  String? _selectedVersion;
  File? _pickedFile;

  bool _running = false;
  bool _done = false;
  String? _error;
  double _progress = 0;
  String _stage = '';

  static const _titles = {
    ImportKind.modpack: '整合包导入',
    ImportKind.mod: '模组导入',
    ImportKind.shader: '光影包导入',
  };
  static const _exts = {
    ImportKind.modpack: ['mrpack', 'zip'],
    ImportKind.mod: ['jar'],
    ImportKind.shader: ['zip'],
  };

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final list = await _versionService.listInstalledVersions();
    setState(() => _installedVersions = list);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _exts[widget.kind],
    );
    if (result?.files.single.path == null) return;
    setState(() {
      _pickedFile = File(result!.files.single.path!);
      _done = false;
      _error = null;
    });
  }

  Future<void> _runImport() async {
    if (_pickedFile == null || _selectedVersion == null) return;
    setState(() {
      _running = true;
      _error = null;
      _progress = 0;
    });
    try {
      switch (widget.kind) {
        case ImportKind.mod:
          await _importService.importMod(_pickedFile!, _selectedVersion!);
          break;
        case ImportKind.shader:
          await _importService.importShaderPack(_pickedFile!, _selectedVersion!);
          break;
        case ImportKind.modpack:
          await _importService.importModpack(
            _pickedFile!,
            _selectedVersion!,
            onProgress: (done, total, current) {
              setState(() {
                _progress = total > 0 ? done / total : 0;
                _stage = current;
              });
            },
          );
          break;
      }
      setState(() {
        _running = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _running = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[widget.kind]!)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.file_open_outlined, color: AppTheme.primary),
                title: Text(
                  _pickedFile != null ? _pickedFile!.uri.pathSegments.last : '选择文件',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '支持: ${_exts[widget.kind]!.join(", ")}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: TextButton(onPressed: _pickFile, child: const Text('选择')),
              ),
            ),
            const SizedBox(height: 12),
            if (_installedVersions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('还没有已安装的游戏版本，请先去"游戏版本安装"',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedVersion,
                dropdownColor: AppTheme.cardDark,
                decoration: const InputDecoration(labelText: '导入到哪个版本'),
                style: const TextStyle(color: Colors.white),
                items: _installedVersions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVersion = v),
              ),
            const SizedBox(height: 24),
            if (_running) ...[
              LinearProgressIndicator(value: widget.kind == ImportKind.modpack ? _progress : null),
              const SizedBox(height: 8),
              Text(_stage, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
            if (_done)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text('导入成功', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_pickedFile != null && _selectedVersion != null && !_running) ? _runImport : null,
              child: const Text('开始导入'),
            ),
          ],
        ),
      ),
    );
  }
}
