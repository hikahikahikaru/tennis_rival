import '../constants/app_strings.dart';

// 試合形式の「種類」「DB用の値」「画面用の文字」を完全にパッケージ化
enum MatchFormat {
  // 定義と同時に、dbValue と label を紐付ける
  oneSet(1, AppStrings.oneSet),
  threeSets(3, AppStrings.threeSets);

  // Enumが持つデータ（外から呼び出せるプロパティ）
  final int dbValue;
  final String label;

  // コンストラクタ（お約束）
  const MatchFormat(this.dbValue, this.label);
}
