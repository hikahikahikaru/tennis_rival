// ① 必要な道具（部品や設定データ）を他のファイルから取り寄せます
import 'package:flutter/material.dart'; // Flutterが用意している基本の画面部品
import '../constants/app_nav_items.dart'; // 自分たちで作った「ボタン5個のデータ一覧」

// ② 画面の下に表示する「ナビゲーションバー」の設計図（クラス）
// StatelessWidget は「一度表示したら自分自身では変化しない部品」を意味します
class CustomBottomNavBar extends StatelessWidget {
  // ③ 外部（この部品を使う画面）から受け取るデータ
  // 現在選ばれているタブの番号（0=ホーム, 1=戦績, 2=登録, 3=グループ, 4=マイページ）
  final int currentIndex;
  // タブがタップされた時に「何をめくるか」という動作の命令
  final Function(int) onTap;

  // ④ この部品を呼び出すときの「お約束」
  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex, // 「使う時は必ず現在のタブ番号を渡してね」という指定
    required this.onTap, // 「使う時は必ずタップ時の命令を渡してね」という指定
  }) : super(key: key);

  // ⑤ 実際に画面に表示する「見た目」を組み立てる場所
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // 受け取った「現在の番号」をセット
      onTap: onTap, // 受け取った「タップ時の命令」をセット

      // ⑥ ボタンを並べる処理（ここが一番重要！）
      // appNavItems（5つのデータが入ったリスト）の中身を1つずつ順番に取り出し、
      // 実際の「画面のボタン部品（BottomNavigationBarItem）」に変換して並べます。
      items: appNavItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(
            item.icon, // データに書いてあるアイコンの種類をセット

            // 【注目】複雑なサイズや色の判定ロジックはデータ側（item）に任せました！
            // 画面側（UI）は「計算済みの結果をちょうだい」とお願いするだけでOKです。
            size: item.iconSize,
            color: item.iconColor,
          ),
          label: item.label, // データに書いてある「ホーム」などの文字をセット
        );
      }).toList(), // 最後に変換したものをリスト形式にまとめ直す
    );
  }
}
