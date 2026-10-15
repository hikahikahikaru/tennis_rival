import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/match_history_item.dart';
import 'package:mobile/models/user_stats.dart';

void main() {
  group('UserStats', () {
    test('calculates total matches and win rate for four wins and two losses',
        () {
      const stats = UserStats(wins: 4, losses: 2);

      expect(stats.totalMatches, 6);
      expect(stats.winRatePercentage, 67);
    });

    test('returns zero win rate when total matches is zero', () {
      const stats = UserStats(wins: 0, losses: 0);

      expect(stats.totalMatches, 0);
      expect(stats.winRatePercentage, 0);
    });

    test('rounds win rate percentage', () {
      const stats = UserStats(wins: 2, losses: 1);

      expect(stats.totalMatches, 3);
      expect(stats.winRatePercentage, 67);
    });

    test('aggregates no matches', () {
      final stats = UserStats.fromMatches(const []);

      expect(stats.totalMatches, 0);
      expect(stats.wins, 0);
      expect(stats.losses, 0);
      expect(stats.winRatePercentage, 0);
    });

    test('aggregates all wins', () {
      final stats = UserStats.fromMatches([
        _match(isWin: true),
        _match(isWin: true),
      ]);

      expect(stats.totalMatches, 2);
      expect(stats.wins, 2);
      expect(stats.losses, 0);
      expect(stats.winRatePercentage, 100);
    });

    test('aggregates all losses', () {
      final stats = UserStats.fromMatches([
        _match(isWin: false),
        _match(isWin: false),
      ]);

      expect(stats.totalMatches, 2);
      expect(stats.wins, 0);
      expect(stats.losses, 2);
      expect(stats.winRatePercentage, 0);
    });

    test('aggregates mixed decided matches and rounds the win rate', () {
      final stats = UserStats.fromMatches([
        _match(isWin: true),
        _match(isWin: true),
        _match(isWin: false),
      ]);

      expect(stats.totalMatches, 3);
      expect(stats.wins, 2);
      expect(stats.losses, 1);
      expect(stats.winRatePercentage, 67);
    });

    test('counts unknown results but excludes them from the win rate', () {
      final stats = UserStats.fromMatches([
        _match(isWin: true),
        _match(isWin: true),
        _match(isWin: true),
        _match(isWin: false),
        _match(isWin: null),
      ]);

      expect(stats.totalMatches, 5);
      expect(stats.wins, 3);
      expect(stats.losses, 1);
      expect(stats.winRatePercentage, 75);
    });

    test('returns zero win rate when all results are unknown', () {
      final stats = UserStats.fromMatches([
        _match(isWin: null),
        _match(isWin: null),
      ]);

      expect(stats.totalMatches, 2);
      expect(stats.wins, 0);
      expect(stats.losses, 0);
      expect(stats.winRatePercentage, 0);
    });

    test('does not mutate the source matches', () {
      final matches = <MatchHistoryItem>[
        _match(isWin: true),
        _match(isWin: null),
      ];
      final original = List<MatchHistoryItem>.of(matches);

      UserStats.fromMatches(matches);

      expect(matches, orderedEquals(original));
    });
  });
}

MatchHistoryItem _match({required bool? isWin}) {
  return MatchHistoryItem(
    matchDate: DateTime(2026, 8, 24),
    opponentName: '対戦相手',
    scoreText: '6-4',
    isWin: isWin,
  );
}
