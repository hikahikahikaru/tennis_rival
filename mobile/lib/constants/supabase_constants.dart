/// Supabase接続に関する設定値・接続情報を管理する定数クラス
///
/// 環境変数（`--dart-define` や `--dart-define-from-file=.env`）から動的に取得します。
/// 未指定時はローカル開発用（44321ポート）がデフォルト値として適用されるため、
/// 通常のローカル起動では引数を省略してそのまま動作させることができます。
class SupabaseConstants {
  SupabaseConstants._();

  /// Supabase の API URL
  ///
  /// 例: `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co`
  /// または `flutter run --dart-define-from-file=.env`
  static const String apiUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:44321',
  );

  /// Supabase の 匿名（anon / Publishable）公開キー
  ///
  /// 例: `flutter run --dart-define=SUPABASE_ANON_KEY=eyJhbGci...`
  /// または `flutter run --dart-define-from-file=.env`
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
}
