import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Üst çubuksuz ana sekme ekranlarının büyük başlığı (Fraunces 26) ve sağdaki eylem.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.trailing,
    this.bottom,
    this.padding = AppPaddings.listHeader,
    super.key,
  });

  final EdgeInsets padding;

  final String title;
  final Widget? trailing;

  /// Başlığın altında duran parça (sekme seçici gibi).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final action = trailing;
    final below = bottom;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
              ?action,
            ],
          ),
          if (below != null) ...[const SizedBox(height: AppSpacing.lg), below],
        ],
      ),
    );
  }
}
