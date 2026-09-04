import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

// アプリ全体のデザイン（色や文字サイズなどのルール）をまとめる場所
class AppTheme {
  // 「ライトモード（通常時）」のデザインルールを作ります
  static ThemeData get lightTheme {
    return ThemeData(
      // ナビゲーションバーの共通ルールをここに一極集中させます
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // 4つ以上アイコンがあっても隠れないようにする設定
        type: BottomNavigationBarType.fixed,
        // 選ばれているときの色（濃い緑）
        selectedItemColor: AppColors.primary,
        // 選ばれていないときの色（グレー）
        unselectedItemColor: AppColors.navIconUnselected,
        // 選ばれているときの文字サイズ
        selectedLabelStyle: const TextStyle(fontSize: AppSizes.navFontSize),
        // 選ばれていないときの文字サイズ
        unselectedLabelStyle: const TextStyle(fontSize: AppSizes.navFontSize),
      ),
    );
  }
}
