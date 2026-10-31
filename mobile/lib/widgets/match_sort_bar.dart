import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/match_sort_condition.dart';

/// 勝敗・試合日の並び順・期間を選択する、試合一覧用の再利用可能な並び替えバー。
class MatchSortBar extends StatelessWidget {
  final MatchSortCondition condition;
  final ValueChanged<MatchSortCondition> onChanged;

  const MatchSortBar({
    super.key,
    required this.condition,
    required this.onChanged,
  });

  static String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';

  Future<void> _pickPeriod(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(AppSizes.matchSortPeriodFirstYear),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: condition.period,
    );
    if (picked != null) onChanged(condition.copyWith(period: picked));
  }

  @override
  Widget build(BuildContext context) {
    final period = condition.period;

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
                period == null
                    ? AppStrings.matchSortPeriodSelect
                    : '${_formatDate(period.start)} - ${_formatDate(period.end)}',
              ),
              onPressed: () => _pickPeriod(context),
            ),
            if (period != null)
              IconButton(
                tooltip: AppStrings.matchSortPeriodClear,
                icon: const Icon(Icons.close),
                onPressed: () =>
                    onChanged(condition.copyWith(clearPeriod: true)),
              ),
          ],
        ),
      ],
    );
  }
}
