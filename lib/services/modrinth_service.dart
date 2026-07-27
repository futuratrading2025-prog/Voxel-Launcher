import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 模组 / 光影 / 整合包下载服务
///
/// 接入 Modrinth 官方公开 API（api.modrinth.com），完全免费、无需密钥，
/// 覆盖模组(mod)、光影(shader)、整合包(modpack)、资源包等内容的搜索与下载，
/// 内容由创作者上传并受 Modrinth 官方审核，来源可信。
enum ContentType { mod, shader, modpack, resourcepack }

class ModrinthService {
  static const String _base = 'https://api.modrinth.com/v2';

  String _facetFor(ContentType t) {
    switch (t) {
      case ContentType.mod:
        return 'mod';
      case ContentType.shader:
        return 'shader';
      case ContentType.modpack:
        return 'modpack';
      case ContentType.resourcepack:
        return 'resourcepack';
    }
  }

  Future<List<ModrinthProject>> search(String query, ContentType type, {String? gameVersion}) async {
    final facets = [
      ['project_type:${_facetFor(type)}'],
      if (gameVersion != null) ['versions:$gameVersion'],
    ];
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'query': query,
      'facets': jsonEncode(facets),
      'limit': '20',
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('搜索失败');
    final data = jsonDecode(resp.body);
    return (data['hits'] as List)
        .map((h) => ModrinthProject(
              id: h['project_id'],
              slug: h['slug'],
              title: h['title'],
              description: h['description'],
              iconUrl: h['icon_url'],
              downloads: h['downloads'],
            ))
        .toList();
  }

  /// 获取某个项目在指定游戏版本下可用的文件版本列表
  Future<List<ModrinthFile>> getVersions(String projectId, {String? gameVersion}) async {
    final uri = Uri.parse('$_base/project/$projectId/version').replace(
      queryParameters: gameVersion != null ? {'game_versions': '["$gameVersion"]'} : null,
    );
    final resp = await http.get(uri);
    final data = jsonDecode(resp.body) as List;
    return data.map((v) {
      final file = (v['files'] as List).firstWhere(
        (f) => f['primary'] == true,
        orElse: () => v['files'][0],
      );
      return ModrinthFile(
        versionNumber: v['version_number'],
        fileName: file['filename'],
        downloadUrl: file['url'],
        sha1: file['hashes']?['sha1'],
      );
    }).toList();
  }

  /// 下载到对应目录：mods / shaderpacks / resourcepacks；整合包单独存放待解析
  Future<File> download(ModrinthFile file, ContentType type, String versionId) async {
    final base = await getApplicationDocumentsDirectory();
    final subDir = switch (type) {
      ContentType.mod => 'mods',
      ContentType.shader => 'shaderpacks',
      ContentType.resourcepack => 'resourcepacks',
      ContentType.modpack => 'modpacks_downloaded',
    };
    final dir = Directory('${base.path}/VoxelLauncher/versions/$versionId/$subDir');
    await dir.create(recursive: true);
    final dest = File('${dir.path}/${file.fileName}');
    final resp = await http.get(Uri.parse(file.downloadUrl));
    await dest.writeAsBytes(resp.bodyBytes);
    return dest;
  }
}

class ModrinthProject {
  final String id, slug, title, description;
  final String? iconUrl;
  final int downloads;
  ModrinthProject({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
    required this.downloads,
  });
}

class ModrinthFile {
  final String versionNumber, fileName, downloadUrl;
  final String? sha1;
  ModrinthFile({
    required this.versionNumber,
    required this.fileName,
    required this.downloadUrl,
    this.sha1,
  });
}
