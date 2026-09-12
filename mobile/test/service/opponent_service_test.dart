import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/service/opponent_service.dart';

void main() {
  group('OpponentService Tests', () {
    setUp(() {
      OpponentService.instance.clearCache();
    });

    test('初期状態ではキャッシュが空であること', () {
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });

    test('loadOpponentsで対戦相手が取得されキャッシュされること', () async {
      final opponents = await OpponentService.instance.loadOpponents();

      expect(opponents, isNotEmpty);
      expect(opponents.length, 2);
      expect(opponents[0].name, '西やん');
      expect(opponents[1].name, 'ピンちゃん');

      // キャッシュプロパティからも同じ値が取得できることを確認
      expect(OpponentService.instance.cachedOpponents.length, 2);
    });

    test('clearCacheでキャッシュがクリアされること', () async {
      await OpponentService.instance.loadOpponents();
      expect(OpponentService.instance.cachedOpponents, isNotEmpty);

      OpponentService.instance.clearCache();
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });
  });
}
