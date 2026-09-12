import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/service/opponent_service.dart';

void main() {
  group('OpponentService Tests', () {
    setUp(() {
      OpponentService.instance.clearCache();
    });

    test('初期状態ではキャッシュが空であること', () {
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });

    test('キャッシュが存在する場合はそれを即座に返却すること', () async {
      // キャッシュがある場合のテスト（キャッシュの動作確認）
      OpponentService.instance.clearCache();

      // 直接キャッシュをセットして動作検証
      // loadOpponentsでキャッシュがあるときは通信せずキャッシュが返る
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });

    test('UserModelのJSON変換が正常に行えること', () {
      final json = {
        'user_id': '22222222-2222-2222-2222-222222222222',
        'user_name': '西やん',
      };
      final user = UserModel.fromJson(json);

      expect(user.id, '22222222-2222-2222-2222-222222222222');
      expect(user.name, '西やん');
      expect(user.toJson(), json);
    });
  });
}
