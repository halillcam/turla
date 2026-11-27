import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/ticket.dart';
import '../utils/ticket_display.dart';

/// İptal onayı: iade tutarını gösterir. Onaylanırsa true döner.
abstract final class CancelTicketDialog {
  static Future<bool> show(BuildContext context, Ticket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.cancelDialogTitle),
        content: Text(ticket.cancelDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancelDialogDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.cancelDialogConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
