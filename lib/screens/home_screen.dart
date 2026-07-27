import 'package:flutter/material.dart';
import '../services/msa_auth_service.dart';
import '../theme/app_theme.dart';
import 'download_hub_screen.dart';
import 'launch_screen.dart';

class HomeScreen extends StatefulWidget {
  final MinecraftAccount account;
  const HomeScreen({super.key, required this.account});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LaunchScreen(account: widget.account),
      const DownloadHubScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Voxel Launcher'),
            const Spacer(),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primary,
              child: Text(widget.account.username.substring(0, 1),
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Text(widget.account.username,
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(width: 4),
            if (!widget.account.isOffline)
              const Icon(Icons.verified, size: 14, color: AppTheme.accent)
            else
              const Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: '启动游戏'),
          NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: '下载'),
        ],
      ),
    );
  }
}
