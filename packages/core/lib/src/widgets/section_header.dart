import 'package:flutter/material.dart';

import '../constants/paddings.dart';
import '../theme/app_text_styles.dart';

/// Küçük büyük harfli bölüm başlığı ("DOĞU KARADENİZ", "PROGRAM") ve sağda isteğe bağlı eylem.
///
/// [title] zaten büyük harfe çevrilmiş verilir (Türkçe İ/ı kuralı `turkishUpper` ile).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.trailing,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final action = trailing;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.eyebrow)),
          if (action != null) ...[const SizedBox(width: AppSpacing.sm), action],
        ],
      ),
    );
  }
}

/// Türkçe büyük harf çevirisi: `i` → `İ`, `ı` → `I` (Dart'ın `toUpperCase`'i `i`'yi `I` yapar).
extension TurkishCase on String {
  String get turkishUpper => replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}
