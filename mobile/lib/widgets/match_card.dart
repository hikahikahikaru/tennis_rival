import 'package:flutter/material.dart';

// 試合一覧の1件分を表示するカード部品
class MatchCard extends StatelessWidget {
  const MatchCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // TODO: 担当者へ - ここに1件分の試合データ（日付、相手、WIN/LOSE、スコア）を表示するUIを実装してください。
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: const Text('試合データのカードをここに実装'),
      ),
    );
  }
}
