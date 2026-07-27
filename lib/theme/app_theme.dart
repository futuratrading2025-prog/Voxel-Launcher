import 'package:flutter/material.dart';

/// Voxel Launcher 主题
/// 视觉风格参考 PCL(Plain Craft Launcher)：
/// 简洁卡片 + 蓝绿主色 + 圆角大按钮 + 侧边导航
class AppTheme {
  static const Color primary = Color(0xFF3C8CE7);
  static const Color primaryDark = Color(0xFF2A5DB0);
  static const Color accent = Color(0xFF00D2A0);
  static const Color bgDark = Color(0xFF14171C);
  static const Color cardDark = Color(0xFF1E222A);
  static const Color textSecondary = Color(0xFFA0A6B1);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: cardDark,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      fontFamily: 'PingFang SC',
    );
  }
}
