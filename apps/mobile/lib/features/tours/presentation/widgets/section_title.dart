import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// İçerik bölümü başlığı ("Tur hakkında", "Tur programı"): Fraunces 18.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPaddings.sectionTitle,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
