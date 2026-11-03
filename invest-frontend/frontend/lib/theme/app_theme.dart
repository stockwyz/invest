import 'package:flutter/material.dart';

/// 和原型保持一致的配色 token。红=涨/盈利，绿=跌/亏损（A 股习惯）；
/// 蓝色只作为品牌色/图表基准线/按钮，不与盈亏含义混用。
class AppColors {
  AppColors._();

  static const background = Color(0xFFF6F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFECECE8);
  static const divider = Color(0xFFF1F1EE);

  static const textPrimary = Color(0xFF17171A);
  static const textSecondary = Color(0xFF6B6B70);
  static const textMuted = Color(0xFF9A9A9E);

  static const brand = Color(0xFF2F6FED);
  static const brandTint = Color(0xFFEEF3FE);

  static const gain = Color(0xFFE5473C); // 红：涨 / 盈利 / 买入方向
  static const gainTint = Color(0xFFFDEEEC);
  static const loss = Color(0xFF12A05C); // 绿：跌 / 亏损 / 卖出方向
  static const lossTint = Color(0xFFEAFAF1);

  static const stock = Color(0xFF2F6FED);
  static const future = Color(0xFFF2994A);
  static const option = Color(0xFF8B5CF6);

  static Color pnlColor(num value) => value >= 0 ? gain : loss;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null, // 使用各平台系统字体（iOS: San Francisco / Android: Roboto）
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
