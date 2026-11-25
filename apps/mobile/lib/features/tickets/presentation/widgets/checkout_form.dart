import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/submit_button.dart';
import '../../../auth/presentation/utils/auth_validators.dart';
import '../../domain/entities/ticket_failure.dart';
import '../screens/checkout_screen.dart';
import '../utils/ticket_display.dart';
import '../utils/ticket_failure_message.dart';
import 'demo_payment_card.dart';
import 'info_row.dart';

/// Yolcu bilgisi: ad ve telefon.
typedef PassengerSubmit = void Function(String name, String phone);

/// Tur özeti, yolcu adı/telefonu ve demo ödeme. Bilet sadece hesap sahibine kesilir.
class CheckoutForm extends StatefulWidget {
  const CheckoutForm({
    required this.args,
    required this.initialPassengerName,
    required this.initialPhone,
    required this.isSubmitting,
    required this.onSubmit,
    this.failure,
    super.key,
  });

  final CheckoutArgs args;
  final String initialPassengerName;
  final String initialPhone;
  final bool isSubmitting;
  final TicketFailureReason? failure;
  final PassengerSubmit onSubmit;

  @override
  State<CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends State<CheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initialPassengerName);
  late final TextEditingController _phone = TextEditingController(text: widget.initialPhone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_name.text.trim(), _phone.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final args = widget.args;
    final failure = widget.failure;

    return Form(
      key: _formKey,
      child: ListView(
        padding: AppPaddings.screen,
        children: [
          Text(AppStrings.tripSummary, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(args.tourTitle, style: textTheme.titleLarge),
          InfoRow(icon: Icons.business, label: AppStrings.organizer, value: args.companyName),
          InfoRow(icon: Icons.event, label: AppStrings.departureDate, value: args.departureLabel),
          const SizedBox(height: AppSpacing.lg),
          Text(AppStrings.passengerSection, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _name,
            enabled: !widget.isSubmitting,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: AppStrings.fullNameLabel,
              helperText: AppStrings.passengerHint,
            ),
            validator: AuthValidators.fullName,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('checkout-phone'),
            controller: _phone,
            enabled: !widget.isSubmitting,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: AppStrings.phoneLabel,
              helperText: AppStrings.phoneHint,
            ),
            validator: AuthValidators.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(AppStrings.paymentSection, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          DemoPaymentCard(priceLabel: args.priceLabel),
          const SizedBox(height: AppSpacing.md),
          Text(AppStrings.cancellationPolicy, style: textTheme.bodySmall),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(failure.message, style: textTheme.bodyMedium?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          SubmitButton(
            label: '${AppStrings.completePayment} (${args.priceLabel})',
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
