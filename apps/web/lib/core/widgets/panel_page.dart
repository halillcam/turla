import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Panel ekranlarının ortak iskeleti: başlık, sağda işlemler, altında içerik.
class PanelPage extends StatelessWidget {
  const PanelPage({required this.title, required this.child, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.panelMaxContentWidth),
        child: Padding(
          padding: AppPaddings.allXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
                  for (final action in actions) ...[const SizedBox(width: AppSpacing.sm), action],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
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
    return Chip(
      label: Text(isActive ? activeLabel : passiveLabel),
      backgroundColor: isActive ? AppColors.primaryLight : AppColors.surfaceMuted,
      visualDensity: VisualDensity.compact,
    );
  }
}
