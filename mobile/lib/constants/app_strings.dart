class AppStrings {
  static const String appName = 'Tennis Rival';

  // ナビゲーションバーで使用
  static const String navHome = 'ホーム';
  static const String navStats = '戦績';
  static const String navEntry = '登録';
  static const String navGroup = 'グループ';
  static const String navProfile = 'マイページ';

  // SignUpScreen
  static const String signUpTitle = 'アカウント登録';
  static const String signUpDescription =
      'Tennis Rivalをはじめるために、アカウント情報を入力してください。';
  static const String signUpDisplayNameLabel = '表示名';
  static const String signUpDisplayNameHint = '例：たけし';
  static const String signUpEmailLabel = 'メールアドレス';
  static const String signUpEmailHint = '例：name@example.com';
  static const String signUpPasswordLabel = 'パスワード';
  static const String signUpPasswordHint = '8文字以上で入力';
  static const String signUpConfirmPasswordLabel = 'パスワード（確認用）';
  static const String signUpConfirmPasswordHint = 'パスワードをもう一度入力';
  static const String signUpDisplayNameRequired = '表示名を入力してください';
  static const String signUpEmailRequired = 'メールアドレスを入力してください';
  static const String signUpEmailInvalid = 'メールアドレスの形式が正しくありません';
  static const String signUpPasswordTooShort = 'パスワードは8文字以上で入力してください';
  static const String signUpConfirmPasswordRequired = '確認用パスワードを入力してください';
  static const String signUpPasswordMismatch = 'パスワードが一致しません';
  static const String signUpSubmit = 'アカウントを作成する';
  static const String signUpSubmitting = '登録中...';
  static const String signUpCheckEmail = '確認メールをご確認ください';
  static const String signUpCompletedButton = '登録完了';
  static const String signUpConfirmationPending =
      '登録手続きを受け付けました。確認メールが届いた場合は、メール内のリンクから登録を完了してください。';
  static const String signUpCompleted = 'アカウント登録が完了しました';
  static const String signUpFailed = 'アカウントを登録できませんでした。もう一度お試しください';
  static const String signUpNetworkError = '通信に失敗しました。通信環境を確認してもう一度お試しください';
  static const String signUpPasswordShow = 'パスワードを表示';
  static const String signUpPasswordHide = 'パスワードを非表示';
  static const String signUpLoginPrompt = 'すでにアカウントをお持ちの方はこちら';

  // LoginScreen
  static const String loginTitle = 'ログイン';
  static const String loginDescription = 'メールアドレスとパスワードを入力してください';
  static const String loginEmailLabel = 'メールアドレス';
  static const String loginEmailHint = '例：name@example.com';
  static const String loginPasswordLabel = 'パスワード';
  static const String loginPasswordHint = 'パスワードを入力';
  static const String loginEmailRequired = 'メールアドレスを入力してください';
  static const String loginEmailInvalid = 'メールアドレスの形式が正しくありません';
  static const String loginPasswordRequired = 'パスワードを入力してください';
  static const String loginSubmit = 'ログインする';
  static const String loginSubmitting = 'ログイン中...';
  static const String loginCompleted = 'ログインしました';
  static const String loginFailed = 'メールアドレスまたはパスワードを確認してください';
  static const String loginNetworkError = '通信に失敗しました。通信環境を確認してもう一度お試しください';
  static const String loginUnexpectedError = '予期しないエラーが発生しました。もう一度お試しください';
  static const String loginPasswordShow = 'パスワードを表示';
  static const String loginPasswordHide = 'パスワードを非表示';
  static const String loginSignUpPrompt = '新規アカウント登録はこちら';
  static const String authenticationInputInvalid = '入力内容を確認してください';
  static const String authenticationEmailNotConfirmed =
      'メールアドレスの確認が完了していません。確認メールをご確認ください';
  static const String authenticationFailed = 'メールアドレスまたはパスワードを確認してください';
  static const String authenticationNetworkError =
      '通信に失敗しました。通信環境を確認してもう一度お試しください';
  static const String authenticationUnexpectedError = 'ログイン中に予期しないエラーが発生しました';
  static const String logoutTooltip = 'ログアウト';
  static const String logoutFailed = 'ログアウトできませんでした。もう一度お試しください';
  static const String logoutNetworkError = '通信に失敗しました。通信環境を確認してもう一度お試しください';
  static const String logoutUnexpectedError = 'ログアウト中に予期しないエラーが発生しました';
  // アカウント登録で使用
  static const String accountRegistrationInputInvalid = '入力内容を確認してください';
  static const String accountDisplayNameRequired = '表示名を入力してください';
  static const String accountEmailRequired = 'メールアドレスを入力してください';
  static const String accountEmailInvalid = 'メールアドレスの形式が正しくありません';
  static const String accountPasswordTooShort = 'パスワードは8文字以上で入力してください';
  static const String accountPasswordMismatch = 'パスワードが一致しません';
  static const String accountRegistrationConfirmationPending =
      '登録手続きを受け付けました。確認メールが届いた場合は、メール内のリンクから登録を完了してください。';
  static const String accountRegistrationCompleted = 'アカウント登録が完了しました';
  static const String accountRegistrationFailed =
      'アカウントを登録できませんでした。入力内容を確認してください';
  static const String accountRegistrationNetworkError =
      '通信に失敗しました。通信環境を確認してもう一度お試しください';
  static const String accountRegistrationUnexpectedError =
      'アカウント登録中にエラーが発生しました';
  // ホーム画面で使用
  static const String recordMatch = '試合結果を記録';
  static const String homeGreeting = 'こんにちは、たけしさん';
  static const String homeRecentMatchesTitle = '最近の試合';
  static const String homeNotificationTooltip = '通知';
  static const String homeNotificationUnavailable = '通知機能は未実装です';
  static const String homePendingMatchUnavailable = '確認待ち画面は未実装です';
  static const String homeNavUnavailable = 'この機能は未実装です';
  static const String homeRecentMatchesLoading = '試合履歴を読み込み中です';
  static const String homeRecentMatchesEmpty = '最近の試合はまだありません';
  static const String homeRecentMatchesFetchFailed = '試合履歴の取得に失敗しました';
  static const String homeStatsLoading = '今月の戦績を読み込み中です';
  static const String homeStatsFetchFailed = '今月の戦績の取得に失敗しました';
  static const String matchHistoryStatsTitle = '月間戦績';
  static const String matchHistoryMatchListTitle = '試合一覧';
  static const String matchHistoryMatchesLoading = '試合一覧を読み込み中です';
  static const String matchHistoryMatchesEmpty = 'この月の試合はありません';
  static const String matchHistoryMatchesFetchFailed = '試合一覧の取得に失敗しました';
  static const List<String> weekdaysJapanese = [
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日',
  ];
  static const String matchCalendarPreviousMonth = '前月';
  static const String matchCalendarNextMonth = '翌月';
  static String matchCalendarMonth(int year, int month) => '$year年$month月';

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
  static const String matchCardUnknown = '判定不能';
  static const String matchCardVs = 'vs';
  static const String matchOpponentUnknown = '対戦相手不明';
  static const String matchScoreUnknown = 'スコア不明';
  static const String matchDetailTitle = '試合詳細';
  static const String matchDetailLoading = '試合詳細を読み込み中です';
  static const String matchDetailFetchFailed = '試合詳細の取得に失敗しました';
  static const String matchDetailIdMissing = '試合詳細を取得できません';
  static const String matchDetailSetCount = 'セットカウント';
  static const String matchDetailMemoEmpty = 'メモはまだありません';
  static const String matchDetailMemoEditTooltip = '個人メモを編集';
  static const String matchDetailMemoCancel = 'キャンセル';
  static const String matchDetailMemoSave = '保存する';
  static const String matchDetailMemoSaving = '保存中...';
  static const String matchDetailMemoSaveFailed = 'メモの保存に失敗しました。もう一度お試しください';
  static const String matchDetailClose = '閉じる';
  // GroupListScreen / GroupCard
  static const String groupListTitle = 'グループ';
  static const String groupListSectionTitle = '所属グループ';
  static const String groupListEmpty = '所属しているグループはまだありません';
  static const String groupListLoading = 'グループを読み込み中です';
  static const String groupListFetchFailed = 'グループの取得に失敗しました';
  static const String groupCreate = 'グループ作成';
  static const String groupJoin = 'グループに参加';
  static const String groupUnavailable = 'この機能は未実装です';
  static String groupMemberCount(int count) => 'メンバー $count人';
  // StatsCard
  static const String statsCardTitle = '今月の戦績';
  static const String statsCardWinRateLabel = '勝率';
  static String statsCardMatchCount(int totalMatches) => '$totalMatches試合';
  static String statsCardRecord(int wins, int losses) => '$wins勝 $losses敗';
  static String statsCardWinRate(int winRatePercentage) =>
      '$winRatePercentage%';
  // PendingMatchCard
  static const String pendingMatchCardTitle = '確認待ちの試合';
  static const String pendingMatchCardConfirm = '確認する';
  static String pendingMatchCardCount(int pendingCount) => '$pendingCount件';
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
  static const String matchRegistrationFailed = '試合結果の登録に失敗しました。もう一度お試しください';

  // GroupCreateScreen
  static const String groupCreateTitle = 'グループ作成';
  static const String groupNameLabel = 'グループ名';
  static const String groupNameHint = '例：週末テニス';
  static const String groupNameRequired = 'グループ名を入力してください';
  static const String groupDescriptionLabel = 'グループの説明（任意）';
  static const String groupDescriptionHint = '例：毎週土曜日に活動するテニス仲間';
  static const String groupCreateNote = '作成後、メンバーを招待できます。';
  static const String groupCreating = '作成中...';
  static const String groupCreateFailed = 'グループの作成に失敗しました';
  static const String groupAuthenticationRequired = 'ログインが必要です';
  static const String requiredMark = '※';

  // GroupJoinScreen
  static const String groupJoinTitle = 'グループ参加';
  static const String groupInviteCodeLabel = '招待コード';
  static const String groupInviteCodeHint = '例：ABC123';
  static const String groupInviteCodeRequired = '招待コードを入力してください';
  static const String groupInviteCodeInfoTitle = '招待コードとは？';
  static const String groupInviteCodeInfoBody =
      'グループの作成者から共有されたコードを入力すると、グループに参加できます。';
  static const String groupJoinUnavailable = 'グループ参加は未実装です';

  // GroupDetailScreen
  static const String groupDetailTitle = 'グループ詳細';
  static const String groupTabMembers = 'メンバー';
  static const String groupTabMatches = '戦績';
  static const String groupMemberListTitle = 'メンバー一覧';
  static const String groupMatchListTitle = 'グループ内の試合';
  static const String groupAdminBadge = '管理者';
  static const String groupInviteCodeTitle = '招待コード';
  static const String groupInviteCodeCopy = 'コピー';
  static const String groupInviteCodeCopied = '招待コードをコピーしました';
  static const String groupInviteCodeNote = 'このコードを共有して、メンバーを招待できます。';
  static const String groupInfoExpandTooltip = 'グループ情報を開く';
  static const String groupInfoCollapseTooltip = 'グループ情報を折りたたむ';
  static const String groupMemberListEmpty = 'メンバーはまだいません';
  static const String groupMatchListEmpty = 'グループ内の試合はまだありません';
  static const String groupDetailNotFound = 'グループ情報が見つかりません';
  static String groupMemberSectionCount(int count) => '$count人';
  static String groupMatchSectionCount(int count) => '$count件';
  static String groupCreatedDate(String date) => '作成日：$date';
  static String groupAdminName(String name) => '管理者：$name';
  static String groupMemberRecord(int wins, int losses, int winRate) =>
      '$wins勝 $losses敗（勝率$winRate%）';
  static String groupMatchVersus(String player1, String player2) =>
      '$player1 vs $player2';
  static String groupMatchWinner(String name) => '勝者：$name';
  static String groupMatchScore(String score) => 'スコア：$score';

  // GroupMemberStatsScreen
  static String memberStatsTitle(String name) => '$nameの戦績';
  static String memberStatsSubtitle(String groupName) => '$groupNameでの対戦成績';
  static const String memberStatsMatchCountLabel = '試合数';
  static const String memberStatsWinsLabel = '勝ち';
  static const String memberStatsLossesLabel = '負け';
  static const String memberStatsWinRateLabel = '勝率';
  static String memberStatsWins(int wins) => '$wins勝';
  static String memberStatsLosses(int losses) => '$losses敗';
  static const String memberStatsTabAll = '全試合';
  static const String memberStatsTabWins = '勝ち試合';
  static const String memberStatsTabLosses = '負け試合';
  static const String memberStatsMatchListTitle = '試合一覧';
  static const String memberStatsMatchListEmpty = '該当する試合はありません';
  static const String memberStatsBadgeWin = '勝ち';
  static const String memberStatsBadgeLose = '負け';
  static String memberStatsSectionCount(int count) => '全$count試合';
  static String memberStatsVersus(String opponent) => 'vs $opponent';

  // エラー・ログ用メッセージ
  static String errorOpponentFetch(Object error) =>
      '対戦相手の取得中にエラーが発生しました: $error';
  static String errorMatchHistoryFetch(Object error) =>
      '試合履歴の取得中にエラーが発生しました: $error';
  static String errorMatchRegistration(Object error) =>
      '試合結果の登録中にエラーが発生しました: $error';
}
