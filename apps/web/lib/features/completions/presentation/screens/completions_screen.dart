import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/panel_page.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/completion_request.dart';
import '../cubit/completions_cubit.dart';
import '../widgets/completion_tile.dart';

/// Rehberlerin "turu bitir" talepleri: onay / ret.
class CompletionsScreen extends StatelessWidget {
  const CompletionsScreen({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CompletionsCubit>(param1: companyId)..load(),
      child: const _CompletionsView(),
    );
  }
}

class _CompletionsView extends StatelessWidget {
  const _CompletionsView();

  Future<void> _review(
    BuildContext context,
    CompletionRequest request, {
    required bool approve,
  }) async {
    final cubit = context.read<CompletionsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: approve ? AppStrings.approveConfirmTitle : AppStrings.rejectConfirmTitle,
      message: approve ? AppStrings.approveConfirmMessage : AppStrings.rejectConfirmMessage,
      confirmLabel: approve ? AppStrings.approve : AppStrings.reject,
    );
    if (!confirmed) return;
    final result = await cubit.review(request, approve: approve);
    if (!context.mounted) return;
    showMessage(context, result.isSuccess ? AppStrings.saved : result.failure!.message);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompletionsCubit>().state;
    final cubit = context.read<CompletionsCubit>();

    return PanelPage(
      title: AppStrings.completionsTitle,
      actions: [
        IconButton(
          onPressed: state.status == LoadStatus.loading ? null : cubit.load,
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.retry,
        ),
      ],
      child: switch (state.status) {
        LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
        LoadStatus.failure => StatusView.message(
          message: state.loadFailure!.message,
          onAction: cubit.load,
        ),
        LoadStatus.ready when state.requests.isEmpty => const StatusView.message(
          message: AppStrings.completionsEmpty,
        ),
        LoadStatus.ready => ListView(
          children: [
            for (final request in [...state.pending, ...state.reviewed])
              Padding(
                padding: AppMargins.cardList,
                child: CompletionTile(
                  request: request,
                  isBusy: state.busyRequestId == request.id,
                  onApprove: () => _review(context, request, approve: true),
                  onReject: () => _review(context, request, approve: false),
                ),
              ),
          ],
        ),
      },
    );
  }
}
