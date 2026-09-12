/// Supabase接続に関する設定値・接続情報を管理する定数クラス
class SupabaseConstants {
  SupabaseConstants._();

  /// Supabase の API URL（ローカル環境: 衝突回避のため44321ポート）
  static const String apiUrl = 'http://127.0.0.1:44321';

  /// Supabase の 匿名（anon）公開キー
  static const String anonKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
}
