class AppStrings {
  // ナビゲーションバーで使用
  static const String navHome = 'ホーム';
  static const String navStats = '戦績';
  static const String navEntry = '登録';
  static const String navGroup = 'グループ';
  static const String navProfile = 'マイページ';
  // ホーム画面で使用
  static const String recordMatch = '試合結果を記録';

  // 試合登録画面で使用
  static const String matchInfo = '試合情報';
  static const String matchDate = '試合日';
  static const String opponent = '対戦相手';
  static const String selectOpponent = '対戦相手を選択';
  static const String opponentNotFound = '対戦相手が見つかりません';
  static const String opponentFetchFailed = '対戦相手の取得に失敗しました';
  static const String retry = '再試行';
  static const String unselected = '未選択';
  static const String matchFormat = '試合形式';
  static const String oneSet = '1セット';
  static const String threeSets = '3セット';
  static const String matchEntryScoreRequired = '通常スコアを入力してください';
  static const String dummyOpponentSearch = 'ここに将来、対戦相手の検索・選択UIが入ります';
  static const String matchCardWin = 'WIN';
  static const String matchCardLose = 'LOSE';
  static const String matchCardVs = 'vs';
  // StatsCard
  static const String statsCardTitle = '今月の戦績';
  static const String statsCardWinRateLabel = '勝率';
  static String statsCardRecord(int wins, int losses) => '$wins勝 $losses敗';
  static String statsCardWinRate(int winRatePercentage) =>
      '$winRatePercentage%';
  // Score 入力周り
  static const String scoreSectionTitle = 'スコア';
  static const String scoreMy = '自分';
  static const String scoreOpponent = '相手';
  static const String scoreSet = 'セット';
  // スコア選択UI
  static const String scoreClear = 'クリア';
  static const String scoreOther = 'その他';
  static const String scoreTiebreakerLabel = 'タイブレーク';
  static const String scoreTiebreakerFormat = '（自分のポイント - 相手のポイント）';
  // 完了画面（RequestSent）で使用
  static const String requestSentTitle = '確認依頼';
  static const String requestSentMain = '確認依頼を送信しました';
  static String requestSentSub(String opponentName) => '$opponentNameさんの確認待ちです';
  static const String requestSentDetail = '対戦相手に通知を送信しました';
  static const String returnToHome = 'ホームに戻る';

  // 確認画面
  static const String matchConfirmTitle = '入力内容を確認';
  static const String matchConfirmResult = '試合結果';
  static const String matchConfirmMemo = '個人メモ';
  static const String matchConfirmMemoNote = '相手には表示されません';
  static const String matchConfirmMemoEmpty = 'なし';
  static const String matchConfirmWin = 'あなたの勝ち';
  static const String matchConfirmLose = 'あなたの負け';
  static const String matchConfirmUndecided = '結果未確定';
  static const String matchConfirmNotice = '送信後は相手の承認まで「確認待ち」になります';
  static const String matchConfirmEdit = '修正する';
  static const String matchConfirmRequest = '相手に確認依頼を送る';

  // エラー・ログ用メッセージ
  static String errorOpponentFetch(Object error) =>
      '対戦相手の取得中にエラーが発生しました: $error';
}
