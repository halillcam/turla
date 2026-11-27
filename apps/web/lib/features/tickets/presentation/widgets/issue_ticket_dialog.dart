import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../domain/entities/participant_ticket.dart';
import '../utils/participant_display.dart';

/// Panelden bilet kesme penceresi: müşteri seçimi + isteğe bağlı yolcu adı.
/// [onSubmit] başarılıysa kapanır, değilse hatayı pencerede gösterir.
Future<void> showIssueTicketDialog(
  BuildContext context, {
  required List<StaffMember> customers,
  required Future<ActionResult<ParticipantTicket>> Function(String customerId, String passengerName)
  onSubmit,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _IssueTicketDialog(customers: customers, onSubmit: onSubmit),
);

class _IssueTicketDialog extends StatefulWidget {
  const _IssueTicketDialog({required this.customers, required this.onSubmit});

  final List<StaffMember> customers;
  final Future<ActionResult<ParticipantTicket>> Function(String customerId, String passengerName)
  onSubmit;

  @override
  State<_IssueTicketDialog> createState() => _IssueTicketDialogState();
}

class _IssueTicketDialogState extends State<_IssueTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passenger = TextEditingController();
  String? _customerId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passenger.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final customerId = _customerId;
    if (_submitting || !(_formKey.currentState?.validate() ?? false) || customerId == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(customerId, _passenger.text);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(context);
    } else {
      setState(() {
        _submitting = false;
        _error = result.failure!.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasCustomers = widget.customers.isNotEmpty;

    return AlertDialog(
      title: const Text(AppStrings.issueTicketTitle),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hasCustomers ? AppStrings.issueTicketHint : AppStrings.issueTicketNoCustomers,
                style: textTheme.bodySmall,
              ),
              if (hasCustomers) ...[
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  style: PanelTextStyles.body,
                  initialValue: _customerId,
                  menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                  decoration: const InputDecoration(labelText: AppStrings.issueTicketCustomer),
                  items: [
                    for (final customer in widget.customers)
                      DropdownMenuItem(value: customer.id, child: Text(customer.optionLabel)),
                  ],
                  onChanged: _submitting ? null : (value) => setState(() => _customerId = value),
                  validator: (value) => value == null ? AppStrings.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passenger,
                  enabled: !_submitting,
                  decoration: const InputDecoration(labelText: AppStrings.issueTicketPassenger),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: textTheme.bodyMedium?.copyWith(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        if (hasCustomers)
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: const Text(AppStrings.issueTicket),
          ),
      ],
    );
  }
}
