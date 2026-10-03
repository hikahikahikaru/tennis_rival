import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// 月表示と日付選択だけを担当し、取得済みの試合日を印で示すカレンダー。
class MatchCalendar extends StatelessWidget {
  final DateTime displayedMonth;
  final Iterable<DateTime> matchDates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  const MatchCalendar({
    super.key,
    required this.displayedMonth,
    required this.matchDates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateTime(displayedMonth.year, displayedMonth.month);
    final firstDayOffset = month.weekday % DateTime.daysPerWeek;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekCount = (firstDayOffset + daysInMonth + 6) ~/ 7;
    final matchDateKeys = matchDates.map(_dateKey).toSet();
    final selectedDateKey =
        selectedDate == null ? null : _dateKey(selectedDate!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.matchCalendarPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthHeader(
              month: month,
              onPrevious: () => onMonthChanged(
                DateTime(month.year, month.month - 1),
              ),
              onNext: () => onMonthChanged(
                DateTime(month.year, month.month + 1),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            const _WeekdayHeader(),
            const SizedBox(height: AppSizes.spacingSmall),
            for (var week = 0; week < weekCount; week++)
              Row(
                children: [
                  for (var weekday = 0;
                      weekday < DateTime.daysPerWeek;
                      weekday++)
                    Expanded(
                      child: _buildDayCell(
                        month: month,
                        cellIndex: week * DateTime.daysPerWeek + weekday,
                        firstDayOffset: firstDayOffset,
                        daysInMonth: daysInMonth,
                        matchDateKeys: matchDateKeys,
                        selectedDateKey: selectedDateKey,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime month,
    required int cellIndex,
    required int firstDayOffset,
    required int daysInMonth,
    required Set<int> matchDateKeys,
    required int? selectedDateKey,
  }) {
    final day = cellIndex - firstDayOffset + 1;
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: AppSizes.matchCalendarDayHeight);
    }

    final date = DateTime(month.year, month.month, day);
    final dateKey = _dateKey(date);
    final hasMatch = matchDateKeys.contains(dateKey);
    final isSelected = selectedDateKey == dateKey;

    return Semantics(
      button: true,
      label: '${date.year}年${date.month}月${date.day}日',
      child: InkResponse(
        key: ValueKey('match-calendar-day-$day'),
        onTap: () => onDateSelected(date),
        radius: AppSizes.matchCalendarDayHeight / 2,
        child: SizedBox(
          height: AppSizes.matchCalendarDayHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                key: isSelected
                    ? ValueKey('match-calendar-selected-$day')
                    : null,
                width: AppSizes.matchCalendarSelectedDaySize,
                height: AppSizes.matchCalendarSelectedDaySize,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '$day',
                  style: AppTextStyles.matchCalendarDay.copyWith(
                    color: isSelected ? AppColors.primaryText : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              SizedBox(
                height: AppSizes.matchCalendarDotSize,
                child: hasMatch
                    ? Container(
                        key: ValueKey('match-calendar-dot-$day'),
                        width: AppSizes.matchCalendarDotSize,
                        height: AppSizes.matchCalendarDotSize,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _dateKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: AppStrings.matchCalendarPreviousMonth,
          onPressed: onPrevious,
          iconSize: AppSizes.matchCalendarNavigationIconSize,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            AppStrings.matchCalendarMonth(month.year, month.month),
            textAlign: TextAlign.center,
            style: AppTextStyles.matchCalendarMonth,
          ),
        ),
        IconButton(
          tooltip: AppStrings.matchCalendarNextMonth,
          onPressed: onNext,
          iconSize: AppSizes.matchCalendarNavigationIconSize,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final weekdays = [
      AppStrings.weekdaysJapanese.last,
      ...AppStrings.weekdaysJapanese.take(6),
    ];
    return Row(
      children: [
        for (var index = 0; index < weekdays.length; index++)
          Expanded(
            child: Text(
              weekdays[index],
              textAlign: TextAlign.center,
              style: AppTextStyles.matchCalendarWeekday.copyWith(
                color: switch (index) {
                  0 => AppColors.matchLose,
                  6 => AppColors.calendarSaturday,
                  _ => null,
                },
              ),
            ),
          ),
      ],
    );
  }
}
