import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_format.dart';
import 'package:mobile/models/match_score.dart';
import 'package:mobile/models/match_set_score.dart';

void main() {
  group('MatchScore', () {
    test('completes a one set match with one won set', () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.oneSet,
        setScores: [
          MatchSetScore(myScore: 6, opponentScore: 4),
        ],
      );

      expect(matchScore.setsRequiredToWin, 1);
      expect(matchScore.isCompleted, isTrue);
      expect(matchScore.myWonSetCount, 1);
      expect(matchScore.opponentWonSetCount, 0);
      expect(matchScore.confirmedSetScores, hasLength(1));
    });

    test('completes a three set match in two straight sets', () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.threeSets,
        setScores: [
          MatchSetScore(myScore: 6, opponentScore: 4),
          MatchSetScore(myScore: 6, opponentScore: 3),
          MatchSetScore(myScore: 0, opponentScore: 6),
        ],
      );

      expect(matchScore.setsRequiredToWin, 2);
      expect(matchScore.isCompleted, isTrue);
      expect(matchScore.myWonSetCount, 2);
      expect(matchScore.opponentWonSetCount, 0);
      expect(matchScore.confirmedSetScores, hasLength(2));
    });

    test('completes a three set match when opponent wins two straight sets',
        () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.threeSets,
        setScores: [
          MatchSetScore(myScore: 4, opponentScore: 6),
          MatchSetScore(myScore: 3, opponentScore: 6),
          MatchSetScore(myScore: 6, opponentScore: 0),
        ],
      );

      expect(matchScore.isCompleted, isTrue);
      expect(matchScore.myWonSetCount, 0);
      expect(matchScore.opponentWonSetCount, 2);
      expect(matchScore.isOpponentMatchWin, isTrue);
      expect(matchScore.confirmedSetScores, hasLength(2));
    });

    test('does not complete a three set match when first two sets are split',
        () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.threeSets,
        setScores: [
          MatchSetScore(myScore: 6, opponentScore: 4),
          MatchSetScore(myScore: 4, opponentScore: 6),
        ],
      );

      expect(matchScore.isCompleted, isFalse);
      expect(matchScore.myWonSetCount, 1);
      expect(matchScore.opponentWonSetCount, 1);
      expect(matchScore.confirmedSetScores, isNull);
    });

    test('completes a three set match after a deciding third set', () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.threeSets,
        setScores: [
          MatchSetScore(myScore: 6, opponentScore: 4),
          MatchSetScore(myScore: 4, opponentScore: 6),
          MatchSetScore(myScore: 6, opponentScore: 3),
        ],
      );

      expect(matchScore.isCompleted, isTrue);
      expect(matchScore.myWonSetCount, 2);
      expect(matchScore.opponentWonSetCount, 1);
      expect(matchScore.confirmedSetScores, hasLength(3));
    });

    test('does not count tied sets as won sets', () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.threeSets,
        setScores: [
          MatchSetScore(myScore: 6, opponentScore: 6),
          MatchSetScore(myScore: 6, opponentScore: 4),
        ],
      );

      expect(matchScore.isCompleted, isFalse);
      expect(matchScore.myWonSetCount, 1);
      expect(matchScore.opponentWonSetCount, 0);
      expect(matchScore.confirmedSetScores, isNull);
    });

    test('keeps tiebreak values in confirmed set scores', () {
      const matchScore = MatchScore(
        matchFormat: MatchFormat.oneSet,
        setScores: [
          MatchSetScore(
            myScore: 7,
            opponentScore: 6,
            myTiebreakScore: 8,
            opponentTiebreakScore: 6,
          ),
        ],
      );

      expect(matchScore.isCompleted, isTrue);
      expect(matchScore.confirmedSetScores?.single.displayScore, '7-6 (8-6)');
    });
  });
}
