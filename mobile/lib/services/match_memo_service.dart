import '../repositories/match_memo_repository.dart';
import 'match_history_service.dart';

/// 個人メモの保存方針と、保存後の試合履歴キャッシュ同期を担当する。
class MatchMemoService {
  final MatchMemoRepository _repository;
  final MatchHistoryService _matchHistoryService;

  MatchMemoService({
    MatchMemoRepository? repository,
    MatchHistoryService? matchHistoryService,
  })  : _repository = repository ?? SupabaseMatchMemoRepository(),
        _matchHistoryService =
            matchHistoryService ?? MatchHistoryService.instance;

  Future<String?> savePersonalMemo({
    required String matchId,
    required String userId,
    required String memo,
  }) async {
    final normalizedMemo = memo.trim();
    if (normalizedMemo.isEmpty) {
      await _repository.deletePersonalMemo(
        matchId: matchId,
        userId: userId,
      );
    } else {
      await _repository.upsertPersonalMemo(
        matchId: matchId,
        userId: userId,
        memo: normalizedMemo,
      );
    }

    final savedMemo = normalizedMemo.isEmpty ? null : normalizedMemo;
    _matchHistoryService.updatePersonalMemo(
      currentUserId: userId,
      matchId: matchId,
      personalMemo: savedMemo,
    );
    return savedMemo;
  }
}
