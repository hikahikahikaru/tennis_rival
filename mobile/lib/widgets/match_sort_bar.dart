import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/match_sort_condition.dart';
import 'match_period_dialog.dart';

/// 勝敗・試合日の並び順・期間を選択する、試合一覧用の再利用可能な並び替えバー。
class MatchSortBar extends StatelessWidget {
  final MatchSortCondition condition;
  final ValueChanged<MatchSortCondition> onChanged;

  const MatchSortBar({
    super.key,
    required this.condition,
    required this.onChanged,
  });

  static String? _formatOrNull(DateTime? d) =>
      d == null ? null : MatchPeriodDialog.format(d);

  Future<void> _editPeriod(BuildContext context) async {
    final result = await MatchPeriodDialog.show(
      context,
      from: condition.from,
      to: condition.to,
    );
    if (result == null) return;
    onChanged(
      condition.copyWith(
        from: result.from,
        to: result.to,
        clearFrom: result.from == null,
        clearTo: result.to == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPeriod = condition.from != null || condition.to != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.matchSortChipSpacing,
          children: [
            for (final result in MatchResultFilter.values)
              ChoiceChip(
                label: Text(result.label),
                selected: condition.result == result,
                onSelected: (_) =>
                    onChanged(condition.copyWith(result: result)),
              ),
          ],
        ),
        Wrap(
          spacing: AppSizes.matchSortChipSpacing,
          children: [
            for (final order in MatchDateOrder.values)
              ChoiceChip(
                label: Text(order.label),
                selected: condition.order == order,
                onSelected: (_) => onChanged(condition.copyWith(order: order)),
              ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                hasPeriod
                    ? AppStrings.matchSortPeriodText(
                        _formatOrNull(condition.from),
                        _formatOrNull(condition.to),
                      )
                    : AppStrings.matchSortPeriodSelect,
              ),
              onPressed: () => _editPeriod(context),
            ),
            if (hasPeriod)
              IconButton(
                tooltip: AppStrings.matchSortPeriodClear,
                icon: const Icon(Icons.close),
                onPressed: () => onChanged(
                  condition.copyWith(clearFrom: true, clearTo: true),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
