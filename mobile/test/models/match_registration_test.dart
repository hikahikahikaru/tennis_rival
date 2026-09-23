import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_format.dart';
import 'package:mobile/models/match_registration.dart';
import 'package:mobile/models/match_set_score.dart';

const currentUserId = '11111111-1111-1111-1111-111111111111';
const opponentUserId = '22222222-2222-2222-2222-222222222222';

void main() {
  group('MatchRegistration', () {
    // 登録者をscore1側として保存し、試合履歴の表示順と一致することを確認する。
    test('converts registrant-side scores to RPC parameters', () {
      final registration = MatchRegistration(
        matchDate: DateTime.utc(2026, 9, 22),
        matchFormat: MatchFormat.threeSets,
        currentUserId: currentUserId,
        opponentUserId: opponentUserId,
        setScores: [
          const MatchSetScore(
            myScore: 7,
            opponentScore: 6,
            myTiebreakScore: 8,
            opponentTiebreakScore: 6,
          ),
          const MatchSetScore(myScore: 6, opponentScore: 3),
        ],
      );

      final parameters = registration.toRpcParameters();

      expect(parameters['p_total_set_amount'], 3);
      expect(parameters['p_score1_user_id'], currentUserId);
      expect(parameters['p_score2_user_id'], opponentUserId);
      expect(parameters, isNot(contains('p_winner')));
      expect(parameters['p_set_scores'], [
        {
          'score1': 7,
          'score2': 6,
          'tScore1': 8,
          'tScore2': 6,
        },
        {
          'score1': 6,
          'score2': 3,
          'tScore1': null,
          'tScore2': null,
        },
      ]);
    });
  });
}
