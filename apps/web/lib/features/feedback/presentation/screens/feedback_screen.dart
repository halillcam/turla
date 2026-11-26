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
import '../../../../core/widgets/title_body_form_dialog.dart';
import '../../domain/entities/feedback_item.dart';
import '../cubit/feedback_cubit.dart';
import '../widgets/feedback_card.dart';

/// Geri bildirimler. [companyId] verilirse firma alanı: [canSend] ise firma admini
/// gönderir. Verilmezse super admin tüm firmalarınkini görür ve durumunu değiştirir.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({this.companyId, this.canSend = false, super.key});

  final String? companyId;
  final bool canSend;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedbackCubit>(param1: companyId)..load(),
      child: _FeedbackView(canSend: canSend, canChangeStatus: companyId == null),
    );
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.canSend, required this.canChangeStatus});

  final bool canSend;
  final bool canChangeStatus;

  Future<void> _send(BuildContext context) async {
    final cubit = context.read<FeedbackCubit>();
    final sent = await showTitleBodyFormDialog(
      context,
      title: AppStrings.sendFeedback,
      submitLabel: AppStrings.send,
      titleMaxLength: FeedbackItem.titleMaxLength,
      bodyMaxLength: FeedbackItem.bodyMaxLength,
      onSubmit: (title, body, _) => cubit.send(title: title, body: body),
    );
    if (sent && context.mounted) showMessage(context, AppStrings.feedbackSent);
  }

  Future<void> _setStatus(BuildContext context, FeedbackItem item, FeedbackStatus status) async {
    final result = await context.read<FeedbackCubit>().setStatus(item, status);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.saved : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedbackCubit>();
    final state = context.watch<FeedbackCubit>().state;
    return PanelPage(
      title: AppStrings.feedbackTitle,
      actions: [
        if (canSend)
          FilledButton.icon(
            onPressed: () => _send(context),
            icon: const Icon(Icons.feedback_outlined),
            label: const Text(AppStrings.sendFeedback),
          ),
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
        LoadStatus.ready when state.items.isEmpty => const StatusView.message(
          message: AppStrings.feedbackEmpty,
        ),
        LoadStatus.ready => ListView(
          children: [
            for (final item in state.items)
              Padding(
                padding: AppMargins.cardList,
                child: FeedbackCard(
                  item: item,
                  showCompany: canChangeStatus,
                  onStatusChanged: canChangeStatus
                      ? (status) => _setStatus(context, item, status)
                      : null,
                ),
              ),
          ],
        ),
      },
    );
  }
}
