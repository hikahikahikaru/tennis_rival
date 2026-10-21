import '../constants/app_strings.dart';

/// グループ詳細画面のタブ種別。
enum GroupDetailTab {
  members,
  matches;

  String get label => switch (this) {
        GroupDetailTab.members => AppStrings.groupTabMembers,
        GroupDetailTab.matches => AppStrings.groupTabMatches,
      };
}
