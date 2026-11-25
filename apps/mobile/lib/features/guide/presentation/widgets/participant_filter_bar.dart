import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../cubit/departure_cubit.dart';

/// Tümü / Geldi / Gelmedi süzgeci ve yolcu arama kutusu.
class ParticipantFilterBar extends StatelessWidget {
  const ParticipantFilterBar({
    required this.filter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    super.key,
  });

  final ParticipantFilter filter;
  final ValueChanged<ParticipantFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ParticipantFilter>(
          segments: const [
            ButtonSegment(value: ParticipantFilter.all, label: Text(AppStrings.filterAll)),
            ButtonSegment(value: ParticipantFilter.arrived, label: Text(AppStrings.filterArrived)),
            ButtonSegment(
              value: ParticipantFilter.notArrived,
              label: Text(AppStrings.filterNotArrived),
            ),
          ],
          selected: {filter},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onFilterChanged(selection.first),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: AppStrings.participantSearchHint,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}
