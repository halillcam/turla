import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/failure_messages.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../domain/entities/managed_tour.dart';

/// Kapak görseli önizlemesi ve yükleme düğmesi. Dosya seçilir, baytlar
/// [onUpload]'a verilir (küçültme ve yükleme Cubit'te).
class TourImageSection extends StatelessWidget {
  const TourImageSection({
    required this.imageUrl,
    required this.isBusy,
    required this.onUpload,
    super.key,
  });

  final String? imageUrl;
  final bool isBusy;
  final Future<ActionResult<ManagedTour>> Function(Uint8List bytes) onUpload;

  Future<void> _pick(BuildContext context) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final result = await onUpload(bytes);
    if (context.mounted) {
      showMessage(context, result.isSuccess ? AppStrings.imageUploaded : result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.tourImage, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: SizedBox(
            width: AppSizes.panelImagePreviewWidth,
            height: AppSizes.panelImagePreviewHeight,
            child: url == null
                ? const ColoredBox(
                    color: AppColors.surfaceMuted,
                    child: Center(child: Text(AppStrings.noImage)),
                  )
                : Image.network(url, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pick(context),
          icon: isBusy
              ? const SizedBox.square(
                  dimension: AppSizes.iconSm,
                  child: CircularProgressIndicator(strokeWidth: AppSizes.progressStroke),
                )
              : const Icon(Icons.upload_outlined),
          label: Text(url == null ? AppStrings.uploadImage : AppStrings.replaceImage),
        ),
      ],
    );
  }
}
