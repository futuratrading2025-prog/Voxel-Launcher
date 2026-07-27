import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum ImportKind { modpack, mod, shader }

/// 本地文件导入服务
///
/// - 模组/光影包：直接复制到目标版本的 mods / shaderpacks 目录
/// - 整合包(.mrpack)：这是 Modrinth 官方定义的整合包标准格式——
///   一个 zip，里面有 modrinth.index.json（列出所有模组的官方下载地址+校验值）
///   和 overrides/ 目录（配置文件、资源包等直接覆盖的文件）。
///   导入时按 index 里的官方地址逐个下载模组，再把 overrides 复制进游戏目录。
///   这个过程本身不涉及分发游戏客户端或任何版权文件，只是编排官方下载链接。
class ImportService {
  Future<Directory> _versionDir(String versionId) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/VoxelLauncher/versions/$versionId');
  }

  Future<void> importMod(File file, String targetVersionId) async {
    final dir = Directory('${(await _versionDir(targetVersionId)).path}/mods');
    await dir.create(recursive: true);
    await file.copy('${dir.path}/${file.uri.pathSegments.last}');
  }

  Future<void> importShaderPack(File file, String targetVersionId) async {
    final dir = Directory('${(await _versionDir(targetVersionId)).path}/shaderpacks');
    await dir.create(recursive: true);
    await file.copy('${dir.path}/${file.uri.pathSegments.last}');
  }

  /// 导入 .mrpack 整合包。[onProgress] 回调 (已完成数, 总数, 当前文件名)。
  Future<void> importModpack(
    File mrpackFile,
    String targetVersionId, {
    required void Function(int done, int total, String current) onProgress,
  }) async {
    final versionDir = await _versionDir(targetVersionId);
    final tempExtractDir = Directory('${versionDir.path}/_mrpack_tmp');
    if (await tempExtractDir.exists()) await tempExtractDir.delete(recursive: true);
    await tempExtractDir.create(recursive: true);

    // 1. 解压 mrpack（本质就是个 zip）
    final bytes = await mrpackFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      final outPath = '${tempExtractDir.path}/${entry.name}';
      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    // 2. 读取 modrinth.index.json，按里面登记的官方地址逐个下载模组/资源
    final indexFile = File('${tempExtractDir.path}/modrinth.index.json');
    if (!await indexFile.exists()) {
      throw Exception('不是有效的 .mrpack 整合包（缺少 modrinth.index.json）');
    }
    final index = jsonDecode(await indexFile.readAsString());
    final files = (index['files'] as List?) ?? [];
    final modsDir = Directory('${versionDir.path}/mods');
    await modsDir.create(recursive: true);

    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final relPath = f['path'] as String; // 例如 mods/sodium.jar
      final downloads = (f['downloads'] as List?) ?? [];
      if (downloads.isEmpty) continue;
      final url = downloads.first as String;
      onProgress(i, files.length, relPath.split('/').last);

      final dest = File('${versionDir.path}/$relPath');
      await dest.create(recursive: true);
      final resp = await http.get(Uri.parse(url));
      await dest.writeAsBytes(resp.bodyBytes);
    }

    // 3. 复制 overrides/（配置、资源包等直接文件，整合包作者自己打包的部分，非官方分发的游戏本体）
    final overridesDir = Directory('${tempExtractDir.path}/overrides');
    if (await overridesDir.exists()) {
      await _copyDirectory(overridesDir, versionDir);
    }

    await tempExtractDir.delete(recursive: true);
    onProgress(files.length, files.length, '完成');
  }

  Future<void> _copyDirectory(Directory src, Directory dst) async {
    await for (final entity in src.list(recursive: false)) {
      final newPath = '${dst.path}/${entity.uri.pathSegments.where((s) => s.isNotEmpty).last}';
      if (entity is File) {
        await File(newPath).create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await Directory(newPath).create(recursive: true);
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }
}
