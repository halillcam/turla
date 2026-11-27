import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/completion_request.dart';

/// Tek bir tur bitirme talebi. Bekleyen talepte onay / ret düğmeleri görünür.
class CompletionTile extends StatelessWidget {
  const CompletionTile({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final CompletionRequest request;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static String statusLabel(CompletionStatus status) => switch (status) {
    CompletionStatus.pending => AppStrings.completionPending,
    CompletionStatus.approved => AppStrings.completionApproved,
    CompletionStatus.rejected => AppStrings.completionRejected,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: AppPaddings.card,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.tourTitle, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(Formatters.dateTime(request.departureAt)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${AppStrings.requestedBy}: ${request.guideName} · '
                    '${AppStrings.requestedAt}: ${Formatters.dateTime(request.createdAt)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (request.isPending) ...[
              OutlinedButton(
                onPressed: isBusy ? null : onReject,
                child: const Text(AppStrings.reject),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: isBusy ? null : onApprove,
                child: const Text(AppStrings.approve),
              ),
            ] else
              ToneBadge(
                label: statusLabel(request.status),
                tone: switch (request.status) {
                  CompletionStatus.approved => AppTone.success,
                  CompletionStatus.rejected => AppTone.error,
                  CompletionStatus.pending => AppTone.warning,
                },
              ),
          ],
        ),
      ),
    );
  }
}
