import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Panel ekranlarının ortak iskeleti: Fraunces başlık (+ isteğe bağlı açıklama),
/// sağda işlemler, altında içerik. En fazla 1200 px genişlik, 32 px kenar boşluğu.
class PanelPage extends StatelessWidget {
  const PanelPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final description = subtitle;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.panelMaxContentWidth),
        child: Padding(
          padding: AppPaddings.panelPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: PanelTextStyles.pageTitle),
                        if (description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            description,
                            style: PanelTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final action in actions) ...[const SizedBox(width: AppSpacing.sm), action],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aktif / pasif etiketi.
class ActiveChip extends StatelessWidget {
  const ActiveChip({
    required this.isActive,
    required this.activeLabel,
    required this.passiveLabel,
    super.key,
  });

  final bool isActive;
  final String activeLabel;
  final String passiveLabel;

  @override
  Widget build(BuildContext context) {
    return ToneBadge(
      label: isActive ? activeLabel : passiveLabel,
      tone: isActive ? AppTone.success : AppTone.neutral,
    );
  }
}

/// Tabloyu saran kenarlıklı yüzey (12 px köşe, tam genişlik). Başlık satırı soluk zeminde,
/// köşelerden kırpılır.
class PanelTableCard extends StatelessWidget {
  const PanelTableCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}
