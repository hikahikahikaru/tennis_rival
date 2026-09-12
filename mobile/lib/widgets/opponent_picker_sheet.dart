import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/user_model.dart';
import '../services/opponent_service.dart';

/// 対戦相手を選択するボトムシート（画面下から出るUI）
class OpponentPickerSheet extends StatefulWidget {
  const OpponentPickerSheet({super.key});

  /// シートを呼び出すためのショートカット関数
  ///
  /// モーダルボトムシートを開き、選択された [UserModel] を返却します。
  /// キャンセル時や未選択で閉じた場合は `null` を返します。
  static Future<UserModel?> show(BuildContext context) {
    return showModalBottomSheet<UserModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.bottomSheetRadius),
        ),
      ),
      builder: (BuildContext context) {
        return const OpponentPickerSheet();
      },
    );
  }

  @override
  State<OpponentPickerSheet> createState() => _OpponentPickerSheetState();
}

class _OpponentPickerSheetState extends State<OpponentPickerSheet> {
  List<UserModel>? _opponents;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 対戦相手データを取得（キャッシュ優先、なければ通信）
  Future<void> _loadData({bool forceRefresh = false}) async {
    // キャッシュが存在し強制再取得でなければ即座に反映
    if (!forceRefresh && OpponentService.instance.cachedOpponents.isNotEmpty) {
      setState(() {
        _opponents = OpponentService.instance.cachedOpponents;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final list = await OpponentService.instance.loadOpponents(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _opponents = list;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.bottomSheetPadding),
      height: AppSizes.bottomSheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // シート上部のタイトル見出し
          const Text(
            AppStrings.selectOpponent,
            style: AppTextStyles.opponentPickerTitle,
          ),
          const SizedBox(height: AppSizes.bottomSheetTitleSpacing),

          // 対戦相手リスト / ローディング / エラー表示エリア
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 1. ローディング表示
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    // 2. エラー発生時（再試行ボタン付き）
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.matchLose,
              size: AppSizes.bottomSheetErrorIconSize,
            ),
            const SizedBox(height: AppSizes.bottomSheetErrorSpacing),
            const Text(
              AppStrings.opponentFetchFailed,
              style: AppTextStyles.opponentPickerError,
            ),
            const SizedBox(height: AppSizes.bottomSheetErrorSpacing),
            TextButton.icon(
              onPressed: () => _loadData(forceRefresh: true),
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text(
                AppStrings.retry,
                style: AppTextStyles.retryButton,
              ),
            ),
          ],
        ),
      );
    }

    final opponents = _opponents ?? [];

    // 3. 取得成功だが候補が0人の場合
    if (opponents.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.opponentNotFound,
          style: AppTextStyles.opponentPickerEmpty,
        ),
      );
    }

    // 4. 正常一覧表示
    return ListView.separated(
      itemCount: opponents.length,
      separatorBuilder: (context, index) => const Divider(
        height: AppSizes.bottomSheetDividerHeight,
        color: AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final opponent = opponents[index];
        return _buildOpponentTile(context, opponent);
      },
    );
  }

  /// 各対戦相手のリスト項目（ListTile）を構築するヘルパーメソッド
  Widget _buildOpponentTile(BuildContext context, UserModel opponent) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.bottomSheetTileHorizontalPadding,
        vertical: AppSizes.bottomSheetTileVerticalPadding,
      ),
      // アイコン（ユーザーのアイコン風）
      leading: const CircleAvatar(
        backgroundColor: AppColors.matchWinBackground,
        child: Icon(
          Icons.person,
          color: AppColors.primary,
        ),
      ),
      // ユーザー名
      title: Text(
        opponent.name,
        style: AppTextStyles.opponentPickerItemName,
      ),
      // タップで選択してモーダルを閉じる
      onTap: () {
        Navigator.pop(context, opponent);
      },
    );
  }
}
