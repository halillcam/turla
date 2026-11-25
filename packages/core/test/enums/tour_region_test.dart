import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';

void main() {
  test('TourRegion değerleri veritabanındaki tour_region sırasıyla aynı', () {
    expect(TourRegion.values.map((region) => region.value), [
      'akdeniz',
      'bati_karadeniz',
      'dogu_karadeniz',
      'marmara',
      'ege',
      'ic_anadolu',
      'dogu_anadolu',
      'guneydogu_anadolu',
      'gunubirlik',
      'yurtdisi',
    ]);
  });

  test('Karadeniz ikiye ayrıldı', () {
    expect(TourRegion.fromValue('bati_karadeniz').label, 'Batı Karadeniz');
    expect(TourRegion.fromValue('dogu_karadeniz').label, 'Doğu Karadeniz');
  });
}
