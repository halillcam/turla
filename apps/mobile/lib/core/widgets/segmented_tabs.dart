import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

/// Soluk zemin üstünde eşit genişlikli sekmeler (Yaklaşan / Geçmiş, Tümü / Geldi / Gelmedi).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPaddings.allXs,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: _Segment(
                label: label,
                isSelected: index == selectedIndex,
                onTap: () => onChanged(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.surface : AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smAll,
          side: isSelected
              ? const BorderSide(color: AppColors.border, width: AppSizes.borderWidth)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.segmentHeight),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
