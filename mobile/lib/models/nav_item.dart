import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

// ナビゲーションの1つ分のデータを表すクラス
class NavItem {
  final IconData icon;
  final String label;
  final bool isLarge;

  const NavItem({
    required this.icon,
    required this.label,
    this.isLarge = false,
  });

  // ----- ここから判定ロジックを追加 -----

  // 自分の状態（isLarge）を判定して、適切なサイズを返すメソッド
  double get iconSize {
    return isLarge ? AppSizes.navIconLarge : AppSizes.navIconDefault;
  }

  // 自分の状態（isLarge）を判定して、適切な色を返すメソッド
  // ※nullを返すとThemeのデフォルト色（グレー）が適用されます
  Color? get iconColor {
    return isLarge ? AppColors.primary : null;
  }
}
