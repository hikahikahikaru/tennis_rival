import 'package:flutter/material.dart';
import '../models/nav_item.dart';
import 'app_strings.dart';

// アプリ全体で使うナビゲーションのリスト
const List<NavItem> appNavItems = [
  NavItem(icon: Icons.home, label: AppStrings.navHome),
  NavItem(icon: Icons.bar_chart, label: AppStrings.navStats),
  NavItem(
      icon: Icons.add_circle,
      label: AppStrings.navEntry,
      isLarge: true), // これだけ特別
  NavItem(icon: Icons.group, label: AppStrings.navGroup),
  NavItem(icon: Icons.person_outline, label: AppStrings.navProfile),
];
