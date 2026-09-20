/// DBに保存する試合種別。
enum MatchType {
  singles(1);

  final int dbValue;

  const MatchType(this.dbValue);
}
