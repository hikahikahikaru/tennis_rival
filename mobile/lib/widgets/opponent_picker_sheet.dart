import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

// 対戦相手を選択するボトムシート（画面下から出るUI）
class OpponentPickerSheet extends StatelessWidget {
  const OpponentPickerSheet({super.key});

  // シートを呼び出すためのショートカット関数
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        // 角丸の数字を定数化
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
  Widget build(BuildContext context) {
    return Container(
      // 余白と高さを定数化
      padding: const EdgeInsets.all(AppSizes.bottomSheetPadding),
      height: AppSizes.bottomSheetHeight,
      child: const Center(
        // ダミーテキストも定数化
        child: Text(AppStrings.dummyOpponentSearch),
      ),
    );
  }
}
