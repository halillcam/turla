import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Etiket solda (sabit genişlik), değer sağda iki sütunlu bilgi listesi.
class DetailList extends StatelessWidget {
  const DetailList({required this.items, super.key});

  final List<DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _DetailRow(item: item),
        ],
      ],
    );
  }
}

/// [DetailList] satırı. [isMono] plaka/kimlik gibi değerler için; [onAction] varsa sağda
/// metin düğmesi ("Ara") çıkar.
class DetailItem {
  const DetailItem({
    required this.label,
    required this.value,
    this.isMono = false,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String value;
  final bool isMono;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.item});

  final DetailItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final action = item.onAction;
    final actionLabel = item.actionLabel;
    final valueStyle = item.isMono
        ? AppTextStyles.mono
        : textTheme.labelMedium?.copyWith(fontFeatures: AppTextStyles.tabularFigures);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: AppSizes.detailLabelWidth,
          child: Text(item.label, style: textTheme.bodySmall),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(item.value, style: valueStyle)),
        if (action != null && actionLabel != null)
          TextButton(
            onPressed: action,
            style: TextButton.styleFrom(textStyle: AppTextStyles.labelMedium),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}
