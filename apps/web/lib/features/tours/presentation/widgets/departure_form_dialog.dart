import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../domain/entities/departure.dart';

/// Tarih ekleme / düzenleme penceresi. [onSubmit] başarılıysa kapanır.
///
/// [guides] atanabilecek aktif rehberlerdir. Mevcut atama pasif bir rehbere
/// aitse seçimde [currentGuideName] ile gösterilir ve korunur.
Future<void> showDepartureFormDialog(
  BuildContext context, {
  required String title,
  required List<StaffMember> guides,
  required Future<ActionResult<Departure>> Function(DepartureDraft draft) onSubmit,
  Departure? initial,
  String? currentGuideName,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DepartureFormDialog(
    title: title,
    guides: guides,
    initial: initial,
    currentGuideName: currentGuideName,
    onSubmit: onSubmit,
  ),
);

class _DepartureFormDialog extends StatefulWidget {
  const _DepartureFormDialog({
    required this.title,
    required this.guides,
    required this.onSubmit,
    this.initial,
    this.currentGuideName,
  });

  final String title;
  final List<StaffMember> guides;
  final Departure? initial;
  final String? currentGuideName;
  final Future<ActionResult<Departure>> Function(DepartureDraft draft) onSubmit;

  @override
  State<_DepartureFormDialog> createState() => _DepartureFormDialogState();
}

class _DepartureFormDialogState extends State<_DepartureFormDialog> {
  static const int _pickerYears = 2;
  static const TimeOfDay _defaultTime = TimeOfDay(hour: 8, minute: 0);

  final _formKey = GlobalKey<FormState>();
  late DateTime? _date = widget.initial?.departureAt.toLocal();
  late TimeOfDay _time = widget.initial == null
      ? _defaultTime
      : TimeOfDay.fromDateTime(widget.initial!.departureAt.toLocal());
  late final _capacity = TextEditingController(text: widget.initial?.capacity.toString());
  late final _plate = TextEditingController(text: widget.initial?.busPlate);
  late final _driver = TextEditingController(text: widget.initial?.driverName);
  late final _driverPhone = TextEditingController(text: widget.initial?.driverPhone);
  late String? _guideId = widget.initial?.guideId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _capacity.dispose();
    _plate.dispose();
    _driver.dispose();
    _driverPhone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + _pickerYears, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    final date = _date;
    if (date == null) {
      setState(() => _error = AppStrings.fieldRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(
      DepartureDraft(
        departureAt: DateTime(date.year, date.month, date.day, _time.hour, _time.minute),
        capacity: int.parse(_capacity.text.trim()),
        guideId: _guideId,
        busPlate: Validators.nullIfBlank(_plate.text),
        driverName: Validators.nullIfBlank(_driver.text),
        driverPhone: Validators.nullIfBlank(_driverPhone.text),
      ),
    );
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

  List<DropdownMenuItem<String?>> _guideItems() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(child: Text(AppStrings.noGuide)),
      for (final guide in widget.guides)
        DropdownMenuItem(value: guide.id, child: Text(guide.fullName)),
    ];
    final current = widget.initial?.guideId;
    if (current != null && widget.guides.every((g) => g.id != current)) {
      items.add(
        DropdownMenuItem(value: current, child: Text(widget.currentGuideName ?? AppStrings.empty)),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.dialogWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(date == null ? AppStrings.departureDate : Formatters.date(date)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(_time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _capacity,
                decoration: const InputDecoration(labelText: AppStrings.departureCapacity),
                keyboardType: TextInputType.number,
                validator: Validators.capacity,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                initialValue: _guideId,
                decoration: const InputDecoration(labelText: AppStrings.departureGuide),
                items: _guideItems(),
                onChanged: (value) => setState(() => _guideId = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _plate,
                decoration: const InputDecoration(labelText: AppStrings.busPlate),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _driver,
                      decoration: const InputDecoration(labelText: AppStrings.driverName),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _driverPhone,
                      decoration: const InputDecoration(labelText: AppStrings.driverPhone),
                      validator: Validators.optionalPhone,
                    ),
                  ),
                ],
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
