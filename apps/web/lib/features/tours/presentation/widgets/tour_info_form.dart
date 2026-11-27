import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../domain/entities/managed_tour.dart';
import 'tour_image_section.dart';

/// Tur bilgileri formu. Alanları toplar; kaydetme ve görsel yükleme
/// işini Cubit'e verilen geri çağrılar yapar.
class TourInfoForm extends StatefulWidget {
  const TourInfoForm({
    required this.tour,
    required this.cities,
    required this.isBusy,
    required this.onSave,
    required this.onUploadImage,
    super.key,
  });

  final ManagedTour? tour;
  final List<City> cities;
  final bool isBusy;
  final Future<ActionResult<ManagedTour>> Function(TourDraft draft) onSave;
  final Future<ActionResult<ManagedTour>> Function(Uint8List bytes) onUploadImage;

  @override
  State<TourInfoForm> createState() => _TourInfoFormState();
}

class _TourInfoFormState extends State<TourInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.tour?.title);
  late final _description = TextEditingController(text: widget.tour?.description);
  late final _extra = TextEditingController(text: widget.tour?.extraDetail);
  late final _price = TextEditingController(
    text: widget.tour == null ? '' : Formatters.priceInput(widget.tour!.price),
  );
  late int? _cityId = widget.tour?.cityId;
  late TourRegion? _region = widget.tour?.region;
  late bool _isActive = widget.tour?.isActive ?? true;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _extra.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.isBusy || !(_formKey.currentState?.validate() ?? false)) return;
    final result = await widget.onSave(
      TourDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        extraDetail: _extra.text.trim(),
        price: Validators.parsePrice(_price.text),
        cityId: _cityId!,
        region: _region!,
        isActive: _isActive,
      ),
    );
    if (mounted) {
      showMessage(context, result.isSuccess ? AppStrings.saved : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppPaddings.verticalLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: AppStrings.tourTitle),
              validator: Validators.title,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: AppStrings.tourPrice),
                    validator: Validators.price,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    style: PanelTextStyles.body,
                    menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                    initialValue: _cityId,
                    decoration: const InputDecoration(labelText: AppStrings.tourCity),
                    items: [
                      for (final city in widget.cities)
                        DropdownMenuItem(value: city.id, child: Text(city.name)),
                    ],
                    validator: (value) => value == null ? AppStrings.fieldRequired : null,
                    onChanged: (value) => setState(() => _cityId = value),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<TourRegion>(
                    style: PanelTextStyles.body,
                    menuMaxHeight: AppSizes.dropdownMenuMaxHeight,
                    initialValue: _region,
                    decoration: const InputDecoration(labelText: AppStrings.tourRegion),
                    items: [
                      for (final region in TourRegion.values)
                        DropdownMenuItem(value: region, child: Text(region.label)),
                    ],
                    validator: (value) => value == null ? AppStrings.fieldRequired : null,
                    onChanged: (value) => setState(() => _region = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: AppStrings.tourDescription),
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _extra,
              decoration: const InputDecoration(labelText: AppStrings.tourExtraDetail),
              minLines: 2,
              maxLines: 6,
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.tourActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: widget.isBusy ? null : _save,
              child: const Text(AppStrings.save),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (widget.tour != null)
              TourImageSection(
                imageUrl: widget.tour!.imageUrl,
                isBusy: widget.isBusy,
                onUpload: widget.onUploadImage,
              ),
          ],
        ),
      ),
    );
  }
}
