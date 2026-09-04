import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'constants/app_theme.dart';

void main() {
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
