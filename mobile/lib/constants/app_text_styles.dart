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

  static const TextStyle matchCardDate = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.matchDateText,
  );

  static const TextStyle matchCardOpponent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle matchCardScore = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle matchCardStatus = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
