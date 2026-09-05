import 'package:flutter/material.dart';

/// 全幅で使えるプライマリーボタン（見た目は AppTheme の elevatedButtonTheme に従う）
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle? overrideStyle = height != null
        ? ElevatedButton.styleFrom(minimumSize: Size.fromHeight(height!))
        : null;

    final Widget button = icon == null
        ? ElevatedButton(
            style: overrideStyle,
            onPressed: onPressed,
            child: Text(label),
          )
        : ElevatedButton.icon(
            style: overrideStyle,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );

    return SizedBox(width: double.infinity, child: button);
  }
}
