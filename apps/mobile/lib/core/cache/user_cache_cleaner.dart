import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

import '../session/session_cleanup.dart';

/// Çıkışta kullanıcıya özel önbellekleri (bilet, rehber listeleri, bildirimler) siler.
/// Seçili il ve tur listesi kişisel olmadığı için kalır.
class UserCacheCleaner implements SessionCleanup {
  UserCacheCleaner({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> beforeSignOut(String userId) async {}

  @override
  Future<void> afterSignOut(String userId) async {
    final scoped = [for (final prefix in StorageKeys.userScopedPrefixes) '$prefix$userId'];
    final keys = await _preferences.getKeys();
    for (final key in keys) {
      if (scoped.any(key.startsWith)) await _preferences.remove(key);
    }
  }
}
