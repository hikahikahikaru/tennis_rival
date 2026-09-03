import 'package:flutter/material.dart';

class MatchEntryScreen extends StatelessWidget {
  const MatchEntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('試合結果を記録'),
      ),
      body: const Center(
        // TODO: 担当者へ - ここに試合結果の登録フォーム（試合日、対戦相手、スコア入力など）を実装してください。
        child: Text('試合登録画面のUIをここに実装'),
      ),
    );
  }
}
