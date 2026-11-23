import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/cache/turla_image_cache_manager.dart';

/// Tur görseli. Görsel cihazda önbelleğe alınır; adres yoksa yer tutucu gösterilir.
class TourImage extends StatelessWidget {
  const TourImage({required this.imageUrl, required this.height, super.key});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _Placeholder(height: height);

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: TurlaImageCacheManager.instance,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: AppDurations.normal,
      placeholder: (_, _) => _Placeholder(height: height),
      errorWidget: (_, _, _) => _Placeholder(height: height),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Icon(Icons.landscape_outlined, size: AppSizes.iconXl, color: AppColors.primary),
    );
  }
}
