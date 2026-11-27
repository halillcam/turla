import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Üst çubuk başlığı ve altında küçük açıklama ("Katılımcılar" / "Kapadokya Turu · 28 Kasım").
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (sub != null)
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
