import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_failure.dart';

/// Yüklemeden önce görseli küçültür: en uzun kenar en fazla
/// [AppSizes.uploadImageMaxDimension] piksel, JPEG kalite
/// [AppSizes.uploadImageQuality]. Böylece depolama ve trafik az tutulur.
class ImageResizer {
  const ImageResizer({
    this.maxDimension = AppSizes.uploadImageMaxDimension,
    this.quality = AppSizes.uploadImageQuality,
  });

  final int maxDimension;
  final int quality;

  /// Okunamayan dosyada `PanelFailure(invalidImage)` fırlatır.
  Uint8List resizeToJpeg(Uint8List source) {
    final decoded = _decode(source);
    if (decoded == null) throw const PanelFailure(PanelFailureReason.invalidImage);

    // Telefon fotoğraflarındaki döndürme bilgisi uygulanır.
    final oriented = img.bakeOrientation(decoded);
    final longest = math.max(oriented.width, oriented.height);
    final resized = longest <= maxDimension
        ? oriented
        : img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? maxDimension : null,
            height: oriented.height > oriented.width ? maxDimension : null,
            interpolation: img.Interpolation.average,
          );
    return img.encodeJpg(resized, quality: quality);
  }

  static img.Image? _decode(Uint8List source) {
    try {
      return img.decodeImage(source);
    } on Object {
      return null;
    }
  }
}
