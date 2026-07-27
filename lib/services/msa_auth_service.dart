import 'dart:convert';
import 'package:http/http.dart' as http;

/// 微软正版账号登录服务
///
/// 使用官方 OAuth2 设备码流程（Device Code Flow），这是第三方启动器
/// （如 PCL、HMCL）验证 Minecraft Java 版正版持有权的标准合法方式：
///
/// 1. 向 Microsoft 申请设备码，用户在浏览器输入码完成登录
/// 2. 用拿到的 MSA token 换 Xbox Live token
/// 3. 用 Xbox Live token 换 XSTS token
/// 4. 用 XSTS token 向 Minecraft Services 换 Minecraft 访问令牌
/// 5. 查询该账号名下是否持有 Minecraft Java 版 —— 这一步就是"正版校验"
///
/// 注意：官方不提供"输入邮箱直接查是否购买"的接口，必须走完整的账号登录
/// 授权流程后，才能查询到当前登录账号本身的持有情况。
class MsaAuthService {
  // 你需要在 Azure AD 应用注册门户 (portal.azure.com) 申请一个
  // Application (client) ID，用于设备码登录。这是公开的客户端标识，
  // 不是密钥，可以安全地打包进 App。
  static const String clientId = 'YOUR_AZURE_APP_CLIENT_ID';

  static const String _deviceCodeUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode';
  static const String _tokenUrl =
      'https://login.microsoftonline.com/consumers/oauth2/v2.0/token';
  static const String _xblAuthUrl = 'https://user.auth.xboxlive.com/user/authenticate';
  static const String _xstsAuthUrl = 'https://xsts.auth.xboxlive.com/xsts/authorize';
  static const String _mcLoginUrl =
      'https://api.minecraftservices.com/authentication/login_with_xbox';
  static const String _mcEntitlementUrl =
      'https://api.minecraftservices.com/entitlements/mcstore';
  static const String _mcProfileUrl = 'https://api.minecraftservices.com/minecraft/profile';

  /// 第一步：申请设备码。返回 verification_uri + user_code，
  /// 界面上展示给用户，让他们去浏览器输入。
  Future<DeviceCodeInfo> requestDeviceCode() async {
    final resp = await http.post(
      Uri.parse(_deviceCodeUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'scope': 'XboxLive.signin offline_access',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('获取设备码失败: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return DeviceCodeInfo(
      deviceCode: data['device_code'],
      userCode: data['user_code'],
      verificationUri: data['verification_uri'],
      expiresIn: data['expires_in'],
      interval: data['interval'] ?? 5,
    );
  }

  /// 第二步：轮询设备码状态，直到用户完成登录（或超时/拒绝）
  Future<String> pollForToken(String deviceCode, int intervalSec) async {
    while (true) {
      await Future.delayed(Duration(seconds: intervalSec));
      final resp = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'client_id': clientId,
          'device_code': deviceCode,
        },
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        return data['access_token'];
      }
      final error = data['error'];
      if (error == 'authorization_pending') {
        continue; // 用户还没输完码，继续等
      } else if (error == 'authorization_declined' || error == 'expired_token') {
        throw Exception('登录已取消或过期，请重试');
      }
    }
  }

  /// 第三~五步：拿 MSA token 一路换到 Minecraft 令牌，并核实正版持有权。
  /// 成功则返回 MinecraftAccount；未持有正版会抛出 NotOwnedException。
  Future<MinecraftAccount> loginWithMsaToken(String msaAccessToken) async {
    // 换 Xbox Live token
    final xblResp = await http.post(
      Uri.parse(_xblAuthUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$msaAccessToken',
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT',
      }),
    );
    final xblData = jsonDecode(xblResp.body);
    final xblToken = xblData['Token'];
    final uhs = xblData['DisplayClaims']['xui'][0]['uhs'];

    // 换 XSTS token
    final xstsResp = await http.post(
      Uri.parse(_xstsAuthUrl),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xblToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT',
      }),
    );
    if (xstsResp.statusCode == 401) {
      throw Exception('该微软账号无法用于 Xbox Live（可能是家庭儿童账号限制）');
    }
    final xstsData = jsonDecode(xstsResp.body);
    final xstsToken = xstsData['Token'];

    // 换 Minecraft 访问令牌
    final mcResp = await http.post(
      Uri.parse(_mcLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identityToken': 'XBL3.0 x=$uhs;$xstsToken'}),
    );
    final mcData = jsonDecode(mcResp.body);
    final mcAccessToken = mcData['access_token'];

    // 查询正版持有权（entitlements）—— 这就是"是否买了Java正版"的判定点
    final entResp = await http.get(
      Uri.parse(_mcEntitlementUrl),
      headers: {'Authorization': 'Bearer $mcAccessToken'},
    );
    final entData = jsonDecode(entResp.body);
    final items = (entData['items'] as List?) ?? [];
    final ownsJava = items.isNotEmpty; // 没有游戏物品条目 = 未购买

    if (!ownsJava) {
      throw NotOwnedException('该账号尚未购买 Minecraft Java 版正版');
    }

    // 拉取正版档案（用户名、皮肤、UUID）
    final profResp = await http.get(
      Uri.parse(_mcProfileUrl),
      headers: {'Authorization': 'Bearer $mcAccessToken'},
    );
    if (profResp.statusCode == 404) {
      throw NotOwnedException('该账号未在 Minecraft 创建过正版档案，请先在官网完成初次设置');
    }
    final profData = jsonDecode(profResp.body);

    return MinecraftAccount(
      username: profData['name'],
      uuid: profData['id'],
      accessToken: mcAccessToken,
      isOffline: false,
    );
  }
}

class DeviceCodeInfo {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;
  DeviceCodeInfo({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });
}

class MinecraftAccount {
  final String username;
  final String uuid;
  final String? accessToken;
  final bool isOffline;
  MinecraftAccount({
    required this.username,
    required this.uuid,
    this.accessToken,
    required this.isOffline,
  });
}

class NotOwnedException implements Exception {
  final String message;
  NotOwnedException(this.message);
  @override
  String toString() => message;
}
