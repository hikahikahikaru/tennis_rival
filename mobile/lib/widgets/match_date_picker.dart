import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

// カレンダー（日付ピッカー）を表示するための共通部品
class MatchDatePicker {
  // カレンダーを呼び出し、選ばれた日付（DateTime）を返す処理
  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(AppConstants.calendarFirstYear),
      lastDate: DateTime(AppConstants.calendarLastYear),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
