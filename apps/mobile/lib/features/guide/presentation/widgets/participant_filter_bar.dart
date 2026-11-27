import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../cubit/departure_cubit.dart';

/// Tümü / Geldi / Gelmedi hap süzgeçleri (sayılarıyla) ve yolcu arama kutusu.
class ParticipantFilterBar extends StatelessWidget {
  const ParticipantFilterBar({
    required this.filter,
    required this.arrived,
    required this.notArrived,
    required this.onFilterChanged,
    required this.onSearchChanged,
    super.key,
  });

  final ParticipantFilter filter;
  final int arrived;
  final int notArrived;
  final ValueChanged<ParticipantFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FilterPill(
              label: AppStrings.filterAll,
              count: arrived + notArrived,
              isSelected: filter == ParticipantFilter.all,
              onTap: () => onFilterChanged(ParticipantFilter.all),
            ),
            _FilterPill(
              label: AppStrings.filterArrived,
              count: arrived,
              isSelected: filter == ParticipantFilter.arrived,
              onTap: () => onFilterChanged(ParticipantFilter.arrived),
            ),
            _FilterPill(
              label: AppStrings.filterNotArrived,
              count: notArrived,
              isSelected: filter == ParticipantFilter.notArrived,
              onTap: () => onFilterChanged(ParticipantFilter.notArrived),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: AppStrings.participantSearchHint,
            prefixIcon: Icon(Icons.search, size: AppSizes.iconMd),
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.onPrimary : AppColors.textPrimary;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.pillHeight),
            child: Padding(
              padding: AppPaddings.pill,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.labelMedium.copyWith(color: foreground)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$count',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: foreground,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
