import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/core/cache/user_cache_cleaner.dart';

void main() {
  late SharedPreferencesAsync preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
  });

  test('çıkışta sadece o kullanıcının bilet/rehber/bildirim önbelleği silinir', () async {
    await preferences.setString('${StorageKeys.ticketsByUserPrefix}u1', 'biletler');
    await preferences.setString('${StorageKeys.guideDeparturesPrefix}u1', 'kalkışlar');
    await preferences.setString('${StorageKeys.guideParticipantsPrefix}u1.dep-1', 'yolcular');
    await preferences.setString('${StorageKeys.notificationsByUserPrefix}u1', 'bildirimler');
    await preferences.setString('${StorageKeys.ticketsByUserPrefix}u2', 'başkası');
    await preferences.setInt(StorageKeys.selectedCityId, 46);
    await preferences.setString('${StorageKeys.toursByCityPrefix}46', 'turlar');

    await UserCacheCleaner(preferences: preferences).afterSignOut('u1');

    final keys = await preferences.getKeys();
    expect(keys, {
      '${StorageKeys.ticketsByUserPrefix}u2',
      StorageKeys.selectedCityId,
      '${StorageKeys.toursByCityPrefix}46',
    });
  });
}
