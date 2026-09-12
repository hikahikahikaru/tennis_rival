import 'package:flutter_test/flutter_test.dart';
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
  });
}
