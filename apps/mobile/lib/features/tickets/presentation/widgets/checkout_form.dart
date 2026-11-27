import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/submit_button.dart';
import '../../../auth/presentation/utils/auth_validators.dart';
import '../../domain/entities/ticket_failure.dart';
import '../screens/checkout_screen.dart';
import '../utils/ticket_display.dart';
import '../utils/ticket_failure_message.dart';
import 'checkout_summary_card.dart';
import 'demo_payment_card.dart';

/// Yolcu bilgisi: ad ve telefon.
typedef PassengerSubmit = void Function(String name, String phone);

/// Tur özeti, yolcu adı/telefonu ve demo ödeme; onay düğmesi alta yapışık.
/// Bilet sadece hesap sahibine kesilir.
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

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: AppPaddings.detailBody,
              children: [
                CheckoutSummaryCard(args: args, passengerName: widget.initialPassengerName),
                const SizedBox(height: AppSpacing.xl),
                Text(AppStrings.passengerSection, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.lg),
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
                const DemoPaymentCard(),
                const SizedBox(height: AppSpacing.lg),
                Text(AppStrings.cancellationPolicy, style: textTheme.bodySmall),
                if (failure != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ToneBanner(
                    message: failure.message,
                    tone: AppTone.error,
                    icon: Icons.error_outline,
                  ),
                ],
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: AppPaddings.bottomBar,
              child: SubmitButton(
                label: '${AppStrings.completePayment} · ${args.priceLabel}',
                loadingLabel: AppStrings.preparingTicket,
                isLoading: widget.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
