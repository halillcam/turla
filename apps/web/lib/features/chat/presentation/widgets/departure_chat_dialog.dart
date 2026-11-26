import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../tours/domain/entities/departure.dart';
import '../../domain/entities/panel_chat_message.dart';
import '../cubit/panel_chat_cubit.dart';

/// Tarihin tur sohbeti (firma denetimi): okuma, yazma (tarih açıkken), mesaj silme.
Future<void> showDepartureChatDialog(BuildContext context, {required Departure departure}) =>
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<PanelChatCubit>(
          param1: departure.id,
          param2: departure.status == DepartureStatus.scheduled,
        )..load(),
        child: _DepartureChatDialog(departure: departure),
      ),
    );

/// "Ad · Tur sorumlusu" gibi gönderen etiketi.
String senderLabel(PanelChatMessage message) => switch (message.senderRole) {
  UserRole.guide => '${message.senderName} · ${AppStrings.chatGuideTag}',
  UserRole.admin || UserRole.superAdmin => '${message.senderName} · ${AppStrings.chatCompanyTag}',
  UserRole.customer => message.senderName,
};

class _DepartureChatDialog extends StatefulWidget {
  const _DepartureChatDialog({required this.departure});

  final Departure departure;

  @override
  State<_DepartureChatDialog> createState() => _DepartureChatDialogState();
}

class _DepartureChatDialogState extends State<_DepartureChatDialog> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final result = await context.read<PanelChatCubit>().send(_input.text);
    if (!mounted) return;
    if (result.isSuccess) {
      _input.clear();
    } else {
      showMessage(context, result.failure!.message);
    }
  }

  Future<void> _delete(PanelChatMessage message) async {
    final cubit = context.read<PanelChatCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.chatDeleteTitle,
      message: '${senderLabel(message)}\n\n${message.body}',
      confirmLabel: AppStrings.delete,
    );
    if (!confirmed) return;
    final result = await cubit.delete(message);
    if (mounted && !result.isSuccess) showMessage(context, result.failure!.message);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PanelChatCubit>();
    final state = context.watch<PanelChatCubit>().state;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${AppStrings.chatTitle} · ${Formatters.dateTime(widget.departure.departureAt)}',
            ),
          ),
          IconButton(
            onPressed: state.status == LoadStatus.loading ? null : cubit.load,
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.retry,
          ),
        ],
      ),
      content: SizedBox(
        width: AppSizes.wideDialogWidth,
        height: AppSizes.wideDialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!cubit.canWrite)
              Padding(
                padding: AppMargins.cardList,
                child: Text(AppStrings.chatReadOnlyPanel, style: textTheme.bodySmall),
              ),
            Expanded(
              child: switch (state.status) {
                LoadStatus.initial || LoadStatus.loading => const StatusView.loading(),
                LoadStatus.failure => StatusView.message(
                  message: state.loadFailure!.message,
                  onAction: cubit.load,
                ),
                LoadStatus.ready when state.messages.isEmpty => const StatusView.message(
                  message: AppStrings.chatEmpty,
                ),
                LoadStatus.ready => ListView(
                  reverse: true,
                  children: [
                    for (final message in state.messages)
                      ListTile(
                        title: Text(senderLabel(message), style: textTheme.labelLarge),
                        subtitle: Text(message.body),
                        leading: Text(
                          Formatters.dateTime(message.createdAt),
                          style: textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          tooltip: AppStrings.delete,
                          onPressed: state.isBusy ? null : () => _delete(message),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    if (state.hasMore)
                      Center(
                        child: TextButton(
                          onPressed: cubit.loadMore,
                          child: const Text(AppStrings.chatLoadOlder),
                        ),
                      ),
                  ],
                ),
              },
            ),
            if (cubit.canWrite) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: PanelChatMessage.maxLength,
                      decoration: const InputDecoration(
                        hintText: AppStrings.chatInputHint,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: state.isBusy ? null : _send,
                    child: const Text(AppStrings.send),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.close)),
      ],
    );
  }
}
