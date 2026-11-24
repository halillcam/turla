import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/company.dart';

/// Firma oluşturma / düzenleme penceresi. [onSubmit] başarılıysa kapanır.
Future<Company?> showCompanyFormDialog(
  BuildContext context, {
  required String title,
  required List<City> cities,
  required Future<ActionResult<Company>> Function(CompanyDraft draft) onSubmit,
  Company? initial,
}) => showDialog<Company>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _CompanyFormDialog(title: title, cities: cities, initial: initial, onSubmit: onSubmit),
);

class _CompanyFormDialog extends StatefulWidget {
  const _CompanyFormDialog({
    required this.title,
    required this.cities,
    required this.onSubmit,
    this.initial,
  });

  final String title;
  final List<City> cities;
  final Company? initial;
  final Future<ActionResult<Company>> Function(CompanyDraft draft) onSubmit;

  @override
  State<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<_CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late int? _cityId = widget.initial?.cityId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(
      CompanyDraft(
        name: _name.text.trim(),
        cityId: _cityId,
        phone: Validators.nullIfBlank(_phone.text),
      ),
    );
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(context, result.value);
    } else {
      setState(() {
        _submitting = false;
        _error = result.failure!.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: AppStrings.companyName),
                validator: Validators.name,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                initialValue: _cityId,
                decoration: const InputDecoration(labelText: AppStrings.companyCity),
                items: [
                  for (final city in widget.cities)
                    DropdownMenuItem(value: city.id, child: Text(city.name)),
                ],
                onChanged: (value) => setState(() => _cityId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: AppStrings.companyPhone),
                validator: Validators.optionalPhone,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
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
        FilledButton(onPressed: _submitting ? null : _submit, child: const Text(AppStrings.save)),
      ],
    );
  }
}
