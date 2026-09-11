import 'match_format.dart';
import 'match_set_score.dart';

/// 入力済みのセットスコアから試合成立と取得セット数を判定するモデル。
///
/// Controllerや文字列のparseはUI側に残し、このクラスでは値として確定した
/// MatchSetScoreだけを扱う。
class MatchScore {
  final MatchFormat matchFormat;
  final List<MatchSetScore> setScores;

  const MatchScore({
    required this.matchFormat,
    required this.setScores,
  });

  int get setsRequiredToWin => (matchFormat.setCount ~/ 2) + 1;

  List<MatchSetScore>? get confirmedSetScores {
    final scoresUntilDecision = <MatchSetScore>[];
    var myWonSetCount = 0;
    var opponentWonSetCount = 0;

    for (final setScore in _targetSetScores) {
      scoresUntilDecision.add(setScore);

      if (setScore.myScore == setScore.opponentScore) {
        continue;
      }

      if (setScore.isMyWin) {
        myWonSetCount++;
      } else {
        opponentWonSetCount++;
      }

      if (myWonSetCount >= setsRequiredToWin ||
          opponentWonSetCount >= setsRequiredToWin) {
        return scoresUntilDecision;
      }
    }

    return null;
  }

  bool get isCompleted => confirmedSetScores != null;

  int get myWonSetCount => _wonSetCount(isMyScore: true);

  int get opponentWonSetCount => _wonSetCount(isMyScore: false);

  bool get isMyMatchWin => myWonSetCount >= setsRequiredToWin;

  bool get isOpponentMatchWin => opponentWonSetCount >= setsRequiredToWin;

  List<MatchSetScore> get _targetSetScores =>
      setScores.take(matchFormat.setCount).toList();

  List<MatchSetScore> get _aggregationSetScores =>
      confirmedSetScores ?? _targetSetScores;

  int _wonSetCount({required bool isMyScore}) {
    return _aggregationSetScores.where((setScore) {
      if (setScore.myScore == setScore.opponentScore) {
        return false;
      }

      return isMyScore ? setScore.isMyWin : !setScore.isMyWin;
    }).length;
  }
}
