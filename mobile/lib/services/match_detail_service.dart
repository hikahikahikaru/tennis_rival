import '../models/match_detail.dart';
import '../repositories/match_detail_repository.dart';

/// 画面から試合詳細を取得する入口を提供し、DB通信はRepositoryへ委譲する。
class MatchDetailService {
  static final MatchDetailService instance = MatchDetailService();

  final MatchDetailRepository _repository;

  MatchDetailService({MatchDetailRepository? repository})
      : _repository = repository ?? SupabaseMatchDetailRepository();

  Future<MatchDetail> loadMatchDetail({
    required String matchId,
    required String currentUserId,
  }) {
    return _repository.fetchMatchDetail(
      matchId: matchId,
      currentUserId: currentUserId,
    );
  }
}
