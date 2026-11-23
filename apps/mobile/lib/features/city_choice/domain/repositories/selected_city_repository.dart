/// Kullanıcının seçtiği kalkış ili.
///
/// Seçim her zaman cihazda tutulur (misafir de seçebilir); giriş yapılmışsa
/// profile de yazılır, böylece başka cihazda giriş yapınca seçim gelir.
abstract interface class SelectedCityRepository {
  Future<int?> readSelectedCityId();

  Future<void> saveSelectedCityId(int cityId);
}
