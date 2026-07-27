import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/msa_auth_service.dart';
import '../services/offline_auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// 登录界面
///
/// 重要说明：Minecraft 正版校验官方并不支持"只填邮箱查是否购买"这种模式，
/// 必须让用户通过微软账号完成一次登录授权，登录后系统才能知道这个账号
/// 名下有没有 Minecraft Java 版。这里用的是设备码流程：用户点击按钮后
/// 会看到一个"登录码"，跳转到浏览器输入即可，不需要在 App 内手输密码
/// （避免被盗号风险，也是官方推荐做法）。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _offlineNameCtrl = TextEditingController();
  final _msaService = MsaAuthService();
  final _offlineService = OfflineAuthService();

  bool _loading = false;
  String? _statusText;
  String? _userCode;
  String? _verificationUri;

  Future<void> _startMsaLogin() async {
    setState(() {
      _loading = true;
      _statusText = '正在申请登录码...';
      _userCode = null;
    });
    try {
      final deviceInfo = await _msaService.requestDeviceCode();
      setState(() {
        _userCode = deviceInfo.userCode;
        _verificationUri = deviceInfo.verificationUri;
        _statusText = '请在浏览器中输入下方登录码完成授权';
      });

      final msaToken = await _msaService.pollForToken(
        deviceInfo.deviceCode,
        deviceInfo.interval,
      );

      setState(() => _statusText = '正在验证 Minecraft Java 版持有情况...');
      final account = await _msaService.loginWithMsaToken(msaToken);

      if (!mounted) return;
      setState(() => _statusText = '登录成功，欢迎 ${account.username}');
      await Future.delayed(const Duration(milliseconds: 600));
      _goHome(account);
    } on NotOwnedException catch (e) {
      _showResultDialog('尚未购买正版', e.message, isError: true);
    } catch (e) {
      _showResultDialog('登录失败', e.toString(), isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _offlineLogin() {
    try {
      final account = _offlineService.login(_offlineNameCtrl.text);
      _goHome(account);
    } catch (e) {
      _showResultDialog('离线登录失败', e.toString(), isError: true);
    }
  }

  void _goHome(MinecraftAccount account) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(account: account)),
    );
  }

  void _showResultDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(title, style: TextStyle(color: isError ? Colors.redAccent : AppTheme.accent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.view_in_ar_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Voxel Launcher',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 48),

              // ── 正版登录卡片 ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('正版登录', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('使用微软账号登录，自动校验 Minecraft Java 版持有权',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      if (_userCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.bgDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(_userCode!,
                                  style: const TextStyle(
                                      color: AppTheme.accent, fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => launchUrl(Uri.parse(_verificationUri!)),
                                icon: const Icon(Icons.open_in_browser, size: 16),
                                label: Text('前往 $_verificationUri'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_statusText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              if (_loading)
                                const SizedBox(
                                    width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              if (_loading) const SizedBox(width: 8),
                              Expanded(child: Text(_statusText!, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                            ],
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _startMsaLogin,
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('使用微软账号登录'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 离线登录卡片 ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('离线登录', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('不校验正版，仅本地/局域网可用', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _offlineNameCtrl,
                        decoration: const InputDecoration(hintText: '输入任意用户名 (1~16字符)'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _offlineLogin, child: const Text('离线进入')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
