import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 游戏版本安装服务
///
/// 严格只走 Mojang 官方版本清单接口获取版本列表和下载地址，
/// 不使用任何第三方网盘/个人分享链接 —— 这样才能保证：
/// 1）文件来源可信、不会被篡改替换成恶意程序
/// 2）不侵犯 Mojang/Microsoft 对游戏客户端文件的版权
///
/// 官方清单地址是公开、免鉴权的标准接口，PCL/HMCL 等主流启动器都用它。
class VersionManifestService {
  static const String _manifestUrl =
      'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';

  Future<List<GameVersion>> fetchVersionList() async {
    final resp = await http.get(Uri.parse(_manifestUrl));
    if (resp.statusCode != 200) {
      throw Exception('获取版本列表失败，请检查网络');
    }
    final data = jsonDecode(resp.body);
    final versions = (data['versions'] as List)
        .map((v) => GameVersion(
              id: v['id'],
              type: v['type'], // release / snapshot / old_beta / old_alpha
              url: v['url'],
              releaseTime: v['releaseTime'],
            ))
        .toList();
    return versions;
  }

  /// 下载指定版本的 client.jar 与 version json，带 SHA1 校验，
  /// 通过 [onProgress] 回调 (已下载字节, 总字节, 阶段说明) 更新安装界面进度条。
  Future<void> installVersion(
    GameVersion version, {
    required void Function(int done, int total, String stage) onProgress,
  }) async {
    final dir = await _versionDir(version.id);
    if (!await dir.exists()) await dir.create(recursive: true);

    // 1. 下载该版本的详细 json（里面含 client.jar 下载地址、依赖库列表等）
    onProgress(0, 100, '获取版本详情');
    final detailResp = await http.get(Uri.parse(version.url));
    final detail = jsonDecode(detailResp.body);
    final jsonFile = File('${dir.path}/${version.id}.json');
    await jsonFile.writeAsString(detailResp.body);

    // 2. 下载 client.jar
    final clientInfo = detail['downloads']['client'];
    final jarUrl = clientInfo['url'];
    final expectedSha1 = clientInfo['sha1'];
    final jarFile = File('${dir.path}/${version.id}.jar');
    await _downloadWithProgress(jarUrl, jarFile, onProgress, stage: '下载游戏本体');

    // 3. 校验完整性
    onProgress(99, 100, '校验文件完整性');
    final actualSha1 = sha1.convert(await jarFile.readAsBytes()).toString();
    if (actualSha1 != expectedSha1) {
      await jarFile.delete();
      throw Exception('文件校验失败，可能下载不完整，请重新安装');
    }
    onProgress(100, 100, '安装完成');
  }

  Future<void> _downloadWithProgress(
    String url,
    File dest,
    void Function(int, int, String) onProgress, {
    required String stage,
  }) async {
    final req = http.Request('GET', Uri.parse(url));
    final resp = await http.Client().send(req);
    final total = resp.contentLength ?? 0;
    int received = 0;
    final sink = dest.openWrite();
    await for (final chunk in resp.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received, total, stage);
    }
    await sink.close();
  }

  Future<Directory> _versionDir(String versionId) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/VoxelLauncher/versions/$versionId');
  }

  Future<List<String>> listInstalledVersions() async {
    final base = await getApplicationDocumentsDirectory();
    final versionsDir = Directory('${base.path}/VoxelLauncher/versions');
    if (!await versionsDir.exists()) return [];
    return versionsDir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split('/').last)
        .toList();
  }
}

class GameVersion {
  final String id;
  final String type;
  final String url;
  final String releaseTime;
  GameVersion({required this.id, required this.type, required this.url, required this.releaseTime});
}
