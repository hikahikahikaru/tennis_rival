import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/home_screen.dart';
import 'service/opponent_service.dart';

void main() {
  // Flutterの初期化処理を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // アプリ起動時にバックグラウンドで対戦相手一覧を先読み（非同期プリロード）
  // awaitせずに呼び出すことで、画面の描画をブロックせず高速に起動しつつ、
  // 後でユーザーが対戦相手選択を開いた際に即時表示できるようにキャッシュします。
  OpponentService.instance.loadOpponents();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Rival',
      theme: AppTheme.lightTheme,
      // アプリを起動して最初に表示する画面を指定
      home: const HomeScreen(),
    );
  }
}
