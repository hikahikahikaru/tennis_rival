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
  bool shouldThrow = false;

  @override
  Future<List<UserModel>> fetchGroupOpponents(String userId) async {
    fetchCallCount++;
    if (shouldThrow) {
      throw Exception('DB Connection Error');
    }
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

    test('通信中に並行してloadOpponentsが呼ばれた場合、同一のFutureを待って正しい結果を返却すること', () async {
      // 2回同時に呼び出す（1回目の通信完了前にもう一度呼ばれる状況をシミュレート）
      final future1 = OpponentService.instance.loadOpponents();
      final future2 = OpponentService.instance.loadOpponents();

      final results = await Future.wait([future1, future2]);

      // どちらの呼び出しも空リストにならず、正しいデータを受け取れること
      expect(results[0].length, 2);
      expect(results[1].length, 2);
      expect(results[0][0].name, '西やん');
      expect(results[1][0].name, '西やん');

      // 通信は多重に実行されず1回だけ行われていること
      expect(fakeRepo.fetchCallCount, 1);
    });

    test('通信エラー時に例外が再スローされ、キャッシュが破壊されないこと', () async {
      fakeRepo.shouldThrow = true;

      expect(
        () => OpponentService.instance.loadOpponents(),
        throwsA(isA<Exception>()),
      );

      // キャッシュは空のまま保持されること
      expect(OpponentService.instance.cachedOpponents, isEmpty);
    });

    test('ユーザーIDが異なる場合は別々にキャッシュ・再取得されること', () async {
      const userA = '11111111-1111-1111-1111-111111111111';
      const userB = '99999999-9999-9999-9999-999999999999';

      // ユーザーAで取得
      await OpponentService.instance.loadOpponents(currentUserId: userA);
      expect(fakeRepo.fetchCallCount, 1);

      // ユーザーAの再取得はキャッシュが効く
      await OpponentService.instance.loadOpponents(currentUserId: userA);
      expect(fakeRepo.fetchCallCount, 1);

      // ユーザーBで取得すると別ユーザーなので新しく通信が走る
      await OpponentService.instance.loadOpponents(currentUserId: userB);
      expect(fakeRepo.fetchCallCount, 2);
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
