import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'msa_auth_service.dart';

/// 离线登录：本地生成一个与官方算法一致的离线 UUID
/// （规则：MD5("OfflinePlayer:用户名")，并把版本位改成3），
/// 不联网、不校验正版，仅用于单机/局域网游玩。
class OfflineAuthService {
  MinecraftAccount login(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty || trimmed.length > 16) {
      throw Exception('用户名需为 1~16 个字符');
    }
    final digest = md5.convert(utf8.encode('OfflinePlayer:$trimmed')).bytes;
    // 按官方离线UUID规则修正版本号与变体位
    digest[6] = (digest[6] & 0x0f) | 0x30;
    digest[8] = (digest[8] & 0x3f) | 0x80;
    final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final uuid =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
    return MinecraftAccount(username: trimmed, uuid: uuid, isOffline: true);
  }
}
