import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle primaryButtonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle signUpTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle signUpDescription = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle signUpFeedback = TextStyle(
    fontSize: 14,
    height: 1.5,
  );

  // HomeScreen 用のテキストスタイル
  static const TextStyle homeAppName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle homeGreeting = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle homeSectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  // GroupListScreen / GroupCard 用のテキストスタイル
  static const TextStyle groupListTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupListSectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupCardName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupCardMemberCount = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
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

  static const TextStyle matchInfoTitle = TextStyle(
    fontSize: 18,
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

  // StatsCard 用のテキストスタイル
  static const TextStyle statsCardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle statsCardRecord = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle statsCardWinRateLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle statsCardWinRate = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // PendingMatchCard 用のテキストスタイル
  static const TextStyle pendingMatchCardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle pendingMatchCardBadge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle pendingMatchCardButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
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

  // OpponentPickerSheet（対戦相手選択）用のテキストスタイル
  static const TextStyle opponentPickerTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle opponentPickerItemName = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle opponentPickerEmpty = TextStyle(
    color: AppColors.textSecondary,
  );

  static const TextStyle opponentPickerError = TextStyle(
    color: AppColors.matchLose,
  );

  static const TextStyle retryButton = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
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

  // MatchConfirmScreen 用のテキストスタイル
  static const TextStyle matchConfirmResultScore = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle matchConfirmNotice = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle matchDetailMemo = TextStyle(
    fontSize: 14,
    color: AppColors.matchOpponentText,
  );

  // LabeledTextField 用のテキストスタイル
  static const TextStyle labeledTextFieldLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle labeledTextFieldRequiredMark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.requiredMark,
  );

  static const TextStyle labeledTextFieldHint = TextStyle(
    fontSize: 14,
    color: AppColors.inputHint,
  );

  static const TextStyle groupCreateNote = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle groupFormError = TextStyle(
    fontSize: 14,
    color: AppColors.requiredMark,
  );

  // InfoBox \u7528\u306e\u30c6\u30ad\u30b9\u30c8\u30b9\u30bf\u30a4\u30eb
  static const TextStyle infoBoxTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle infoBoxBody = TextStyle(
    fontSize: 12,
    color: AppColors.matchDateText,
  );

  // MatchCalendar用のテキストスタイル
  static const TextStyle matchCalendarMonth = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle matchCalendarWeekday = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle matchCalendarDay = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.matchOpponentText,
  );

  // GroupDetailScreen 用のテキストスタイル
  static const TextStyle groupDetailName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupDetailDescription = TextStyle(
    fontSize: 14,
    color: AppColors.matchDateText,
  );

  static const TextStyle groupDetailMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle groupDetailInviteCode = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupDetailCopyButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle groupDetailTab = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle groupDetailSectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle groupDetailSectionCount = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle groupDetailAdminBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // GroupMemberStatsScreen 用のテキストスタイル
  static const TextStyle memberStatsName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle memberStatsLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle memberStatsValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.matchOpponentText,
  );

  static const TextStyle memberStatsWinValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.matchWin,
  );

  static const TextStyle memberStatsLoseValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.matchLose,
  );

  static const TextStyle memberStatsWinRate = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
}
