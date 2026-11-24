import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/status_view.dart';
import '../cubit/tour_program_cubit.dart';
import 'program_day_card.dart';

/// Gün gün program. Her değişiklik Cubit'e gider; "Kaydet" tek istek atar.
class ProgramEditor extends StatelessWidget {
  const ProgramEditor({super.key});

  Future<void> _save(BuildContext context) async {
    final result = await context.read<TourProgramCubit>().save();
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.saved : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TourProgramCubit>().state;
    final cubit = context.read<TourProgramCubit>();

    return switch (state.status) {
      LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
      LoadStatus.failure => StatusView.message(
        message: state.loadFailure!.message,
        onAction: cubit.load,
      ),
      LoadStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppPaddings.verticalLg,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.isDirty ? AppStrings.programUnsaved : '',
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: state.isSaving ? null : cubit.addDay,
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addDay),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: state.isSaving || !state.isDirty ? null : () => _save(context),
                  child: const Text(AppStrings.saveProgram),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.items.isEmpty
                ? const StatusView.message(message: AppStrings.programEmpty)
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Padding(
                        key: ValueKey(item.key),
                        padding: AppMargins.cardList,
                        child: ProgramDayCard(
                          dayNo: index + 1,
                          day: item.day,
                          canMoveUp: index > 0,
                          canMoveDown: index < state.items.length - 1,
                          onTitleChanged: (text) => cubit.updateTitle(index, text),
                          onActivitiesChanged: (text) => cubit.updateActivities(index, text),
                          onMoveUp: () => cubit.moveDay(index, -1),
                          onMoveDown: () => cubit.moveDay(index, 1),
                          onRemove: () => cubit.removeDay(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    };
  }
}
