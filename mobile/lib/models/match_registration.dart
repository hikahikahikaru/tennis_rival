import 'match_format.dart';
import 'match_set_score.dart';

/// 登録時にDBへ保存する、シングルス1試合分の入力値。
class MatchRegistration {
  final DateTime matchDate;
  final MatchFormat matchFormat;
  final String currentUserId;
  final String opponentUserId;
  final List<MatchSetScore> setScores;

  const MatchRegistration({
    required this.matchDate,
    required this.matchFormat,
    required this.currentUserId,
    required this.opponentUserId,
    required this.setScores,
  });

  // migrationで定義したcreate_singles_match関数の引数名に合わせて変換する。
  // 試合単位の勝者は、DB関数内で各セットの得点から決定する。
  Map<String, dynamic> toRpcParameters() {
    return {
      'p_dt_match': matchDate.toUtc().toIso8601String(),
      'p_total_set_amount': matchFormat.setCount,
      'p_score1_user_id': currentUserId,
      'p_score2_user_id': opponentUserId,
      'p_set_scores': [
        for (final setScore in setScores)
          {
            'score1': setScore.myScore,
            'score2': setScore.opponentScore,
            'tScore1': setScore.myTiebreakScore,
            'tScore2': setScore.opponentTiebreakScore,
          },
      ],
    };
  }
}
