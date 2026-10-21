import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../models/group_match_summary.dart';

/// グループ内で行われた試合の日付・対戦カード・スコア・勝者を表示するカード。
class GroupMatchCard extends StatelessWidget {
  final GroupMatchSummary match;

  const GroupMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.groupCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.dateText,
                    style: AppTextStyles.matchCardDate,
                  ),
                ),
                Text(
                  AppStrings.groupMatchWinner(match.winnerName),
                  style: AppTextStyles.groupDetailMeta,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.groupCardTextSpacing),
            Text(
              AppStrings.groupMatchVersus(
                match.player1Name,
                match.player2Name,
              ),
              style: AppTextStyles.groupCardName,
            ),
            const SizedBox(height: AppSizes.groupCardTextSpacing),
            Text(
              AppStrings.groupMatchScore(match.scoreText),
              style: AppTextStyles.groupCardMemberCount,
            ),
          ],
        ),
      ),
    );
  }
}
