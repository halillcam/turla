import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import 'info_row.dart';

/// Bilgi satırı + sağda arama düğmesi. Düğmeye basınca telefonun arama uygulaması açılır.
class ContactRow extends StatelessWidget {
  const ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.callTooltip,
    this.onCall,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String callTooltip;

  /// Null ise (telefon yok) düğme gösterilmez.
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoRow(icon: icon, label: label, value: value),
        ),
        if (onCall != null)
          IconButton.filledTonal(
            onPressed: onCall,
            tooltip: callTooltip,
            icon: const Icon(Icons.call, size: AppSizes.iconMd),
          ),
      ],
    );
  }
}
