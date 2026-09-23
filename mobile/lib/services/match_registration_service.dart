import '../models/match_registration.dart';
import '../models/match_format.dart';
import '../models/match_set_score.dart';
import '../repositories/match_registration_repository.dart';

/// 試合登録のユースケースを担当し、DB通信はRepositoryへ委譲する。
class MatchRegistrationService {
  static final MatchRegistrationService instance = MatchRegistrationService();

  final MatchRegistrationRepository _repository;

  MatchRegistrationService({MatchRegistrationRepository? repository})
      : _repository = repository ?? SupabaseMatchRegistrationRepository();

  /// 画面入力をDB登録用のModelへ変換して、シングルスの試合結果を登録する。
  ///
  /// 登録者をscore1側として統一することで、試合履歴でのスコア表示順を保つ。
  Future<String> registerSinglesMatch({
    required DateTime matchDate,
    required MatchFormat matchFormat,
    required String currentUserId,
    required String opponentUserId,
    required List<MatchSetScore> setScores,
    required String clientRequestId,
  }) {
    final registration = MatchRegistration(
      matchDate: matchDate,
      matchFormat: matchFormat,
      currentUserId: currentUserId,
      opponentUserId: opponentUserId,
      setScores: setScores,
      clientRequestId: clientRequestId,
    );
    return _repository.registerMatch(registration);
  }
}
