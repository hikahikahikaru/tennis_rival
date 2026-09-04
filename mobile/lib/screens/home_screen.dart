import 'package:flutter/material.dart';
// import '../widgets/match_card.dart'; // 後で部品を使う時にコメント解除
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tennis Rival - ホーム'),
      ),
      body: const Center(
        // TODO: 担当者へ - ここにホーム画面のUI（こんにちは〇〇さん、今月の戦績など）を実装してください。
        // 「最近の試合」リストは、下で作成する MatchCard ウィジェットを並べて表示するイメージです。
        child: Text('ホーム画面のUIをここに実装'),
      ),
      //下部のナビゲーション
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: 後で画面遷移の処理を書く
          print('タブ $index が押されました');
        },
      ),
    );
  }
}
