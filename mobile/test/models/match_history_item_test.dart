import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_history_item.dart';

const currentUserId = '11111111-1111-1111-1111-111111111111';
const opponentUserId = '22222222-2222-2222-2222-222222222222';

void main() {
  group('MatchHistoryItem', () {
    test('converts opponent-side score and tiebreak to viewer perspective', () {
      final item = MatchHistoryItem.fromRow(
        _row(
          score1UserId: opponentUserId,
          winnerId: currentUserId,
        ),
        currentUserId: currentUserId,
      );

      expect(item, isNotNull);
      expect(item!.opponentName, '西やん');
      expect(item.scoreText, '6-7 (6-8)');
      expect(item.isWin, isTrue);
    });

    test('does not infer score side or winner from inconsistent data', () {
      final item = MatchHistoryItem.fromRow(
        _row(score1UserId: 'unknown-user', winnerId: 'unknown-user'),
        currentUserId: currentUserId,
      );

      expect(item, isNotNull);
      expect(item!.scoreText, 'スコア不明');
      expect(item.isWin, isNull);
    });

    test('shows history-specific text when opponent data is missing', () {
      final row = _row(
        score1UserId: currentUserId,
        winnerId: currentUserId,
      );
      final match = row['matches'] as Map<String, dynamic>;
      match['match_participants'] = [
        {
          'participant_id': currentUserId,
          'users': {'user_name': 'たけし'},
        },
      ];

      final item = MatchHistoryItem.fromRow(
        row,
        currentUserId: currentUserId,
      );

      expect(item, isNotNull);
      expect(item!.opponentName, '対戦相手不明');
    });

    test('formats match date for card display', () {
      final item = MatchHistoryItem(
        matchDate: DateTime(2026, 8, 24),
        opponentName: '西やん',
        scoreText: '6-4',
        isWin: true,
      );

      expect(item.displayDate, '8月24日');
    });
  });
}

Map<String, dynamic> _row({
  required String? score1UserId,
  required String? winnerId,
}) {
  return {
    'match_id': 'match-1',
    'participant_id': currentUserId,
    'matches': {
      'match_id': 'match-1',
      'dt_match': '2026-08-24T10:00:00+09:00',
      'match_type': 1,
      'winner': winnerId,
      'score1_user_id': score1UserId,
      'match_participants': [
        {
          'participant_id': currentUserId,
          'users': {'user_name': 'たけし'},
        },
        {
          'participant_id': opponentUserId,
          'users': {'user_name': '西やん'},
        },
      ],
      'set_scores': [
        {
          'set_no': 1,
          'score1': 7,
          'score2': 6,
          't_score1': 8,
          't_score2': 6,
        },
      ],
    },
  };
}
