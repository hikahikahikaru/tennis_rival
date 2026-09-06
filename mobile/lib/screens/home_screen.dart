import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/primary_button.dart';
import '../constants/app_strings.dart';
import 'match_entry_screen.dart'; // ← 追加：登録画面を読み込む

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tennis Rival - ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: PrimaryButton(
            label: AppStrings.recordMatch,
            // icon: Icons.add, // もし相方さんがアイコン対応を完了していればコメント解除
            onPressed: () {
              // ↓ 追加：ボタンを押したら登録画面へ移動する処理
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MatchEntryScreen(),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          print('タブ $index が押されました');
        },
      ),
    );
  }
}
