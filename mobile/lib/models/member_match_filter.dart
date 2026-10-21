import '../constants/app_strings.dart';
import 'group_member_match.dart';

/// メンバー戦績画面の試合絞り込み種別。
enum MemberMatchFilter {
  all,
  wins,
  losses;

  String get label => switch (this) {
        MemberMatchFilter.all => AppStrings.memberStatsTabAll,
        MemberMatchFilter.wins => AppStrings.memberStatsTabWins,
        MemberMatchFilter.losses => AppStrings.memberStatsTabLosses,
      };

  bool includes(GroupMemberMatch match) => switch (this) {
        MemberMatchFilter.all => true,
        MemberMatchFilter.wins => match.isWin,
        MemberMatchFilter.losses => !match.isWin,
      };
}
