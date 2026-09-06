import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle primaryButtonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // SelectionField用のテキストスタイル
  static const TextStyle selectionFieldTitle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle selectionFieldValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}
