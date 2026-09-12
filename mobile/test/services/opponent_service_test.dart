import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/repositories/user_repository.dart';
import 'package:mobile/services/opponent_service.dart';

/// テスト用のモックリポジトリ
class FakeUserRepository extends UserRepository {
  List<UserModel> dummyUsers = [
    const UserModel(id: '22222222-2222-2222-2222-222222222222', name: '西やん'),
    const UserModel(id: '33333333-3333-3333-3333-333333333333', name: 'ピンちゃん'),
  ];
  int fetchCallCount = 0;

  @override
  Future<List<UserModel>> fetchGroupOpponents(String userId) async {
    fetchCallCount++;
    return dummyUsers;
  }
}

void main() {
  group('OpponentService Tests', () {
    late FakeUserRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeUserRepository();
      OpponentService.instance.userRepository = fakeRepo;
      OpponentService.instance.clearCache();
    });

    test('初期状態ではキャッシュが空であること', () {
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });

    test('loadOpponentsでリポジトリから対戦相手が取得されキャッシュされること', () async {
      final opponents = await OpponentService.instance.loadOpponents();

      expect(opponents.length, 2);
      expect(opponents[0].name, '西やん');
      expect(opponents[1].name, 'ピンちゃん');
      expect(fakeRepo.fetchCallCount, 1);

      // キャッシュプロパティからも同じ値が取得できることを確認
      expect(OpponentService.instance.cachedOpponents.length, 2);

      // 2回目の呼び出しではキャッシュが使われ、リポジトリが再取得されないことを確認
      final cached = await OpponentService.instance.loadOpponents();
      expect(cached.length, 2);
      expect(fakeRepo.fetchCallCount, 1); // 呼び出し回数は増えない
    });

    test('forceRefresh=true の場合はキャッシュがあっても再取得されること', () async {
      await OpponentService.instance.loadOpponents();
      expect(fakeRepo.fetchCallCount, 1);

      await OpponentService.instance.loadOpponents(forceRefresh: true);
      expect(fakeRepo.fetchCallCount, 2);
    });

    test('clearCacheでキャッシュがクリアされること', () async {
      await OpponentService.instance.loadOpponents();
      expect(OpponentService.instance.cachedOpponents, isNotEmpty);

      OpponentService.instance.clearCache();
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
