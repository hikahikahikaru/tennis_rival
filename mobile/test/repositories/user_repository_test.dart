import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/user_model.dart';
import 'package:mobile/repositories/user_repository.dart';

void main() {
  group('UserRepository Tests', () {
    test('インスタンスを正常に生成できること', () {
      final repository = UserRepository();
      expect(repository, isNotNull);
    });

    test('UserModelの相互変換テスト', () {
      final user = const UserModel(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'たけし',
      );
      final json = user.toJson();

      expect(json['user_id'], '11111111-1111-1111-1111-111111111111');
      expect(json['user_name'], 'たけし');

      final reconstructed = UserModel.fromJson(json);
      expect(reconstructed, equals(user));
    });
  });
}
