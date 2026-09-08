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

  // ScoreInputRow 用のテキストスタイル
  static const TextStyle scoreSetLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle scoreInputHeader = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle scoreInputValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle scoreSectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // スコア選択UI（ボトムシート等）関連のテキストスタイル
  static const TextStyle scoreBottomSheetOption = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle scoreTiebreakerLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  // 完了画面関連のテキストスタイル
  static const TextStyle successTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle successSubTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle successDetail = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
