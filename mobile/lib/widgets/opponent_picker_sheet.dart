import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/user_model.dart';
import '../services/opponent_service.dart';

/// 対戦相手を選択するボトムシート（画面下から出るUI）
class OpponentPickerSheet extends StatelessWidget {
  /// 表示する対戦相手ユーザーのリスト
  final List<UserModel> opponents;

  const OpponentPickerSheet({
    super.key,
    required this.opponents,
  });

  /// シートを呼び出すためのショートカット関数
  ///
  /// キャッシュ済みの対戦相手一覧を取得して即座にボトムシートを表示します。
  /// もしキャッシュがまだ無ければその場で非同期取得してから表示します。
  /// 選択された [UserModel] を返却し、キャンセルされた場合は `null` を返します。
  static Future<UserModel?> show(BuildContext context) async {
    // 1. キャッシュが存在するか確認し、未取得の場合は取得処理を待つ
    final list = OpponentService.instance.cachedOpponents.isNotEmpty
        ? OpponentService.instance.cachedOpponents
        : await OpponentService.instance.loadOpponents();

    // 画面遷移中などでcontextが無効になっていないか確認
    if (!context.mounted) return null;

    // 2. モーダルボトムシートを表示し、タップされたユーザーを返す
    return showModalBottomSheet<UserModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        // 角丸の数字を定数化
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.bottomSheetRadius),
        ),
      ),
      builder: (BuildContext context) {
        return OpponentPickerSheet(opponents: list);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 余白と高さを定数化
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

          // 対戦相手リストの表示エリア
          Expanded(
            child: opponents.isEmpty
                ? const Center(
                    // 候補が0件の場合のメッセージ
                    child: Text(
                      AppStrings.opponentNotFound,
                      style: AppTextStyles.opponentPickerEmpty,
                    ),
                  )
                : ListView.separated(
                    itemCount: opponents.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: AppSizes.bottomSheetDividerHeight,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final opponent = opponents[index];
                      return _buildOpponentTile(context, opponent);
                    },
                  ),
          ),
        ],
      ),
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
