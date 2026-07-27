import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const VoxelLauncherApp());
}

class VoxelLauncherApp extends StatelessWidget {
  const VoxelLauncherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxel Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}
