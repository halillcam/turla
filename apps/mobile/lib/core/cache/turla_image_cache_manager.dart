import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:turla_core/turla_core.dart';

/// Tur görselleri için disk önbelleği. Cihazda en fazla
/// [AppSizes.imageCacheMaxObjects] görsel tutulur, [AppDurations.imageCacheStale]
/// süresinden eski olanlar silinir; böylece depolama alanı şişmez.
class TurlaImageCacheManager extends CacheManager with ImageCacheManager {
  TurlaImageCacheManager._()
    : super(
        Config(
          _key,
          stalePeriod: AppDurations.imageCacheStale,
          maxNrOfCacheObjects: AppSizes.imageCacheMaxObjects,
        ),
      );

  static const String _key = 'turlaTourImages';

  static final TurlaImageCacheManager instance = TurlaImageCacheManager._();
}
