import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/tours/data/models/tour_model.dart';
import 'package:turla_mobile/features/tours/presentation/cubit/tour_list_cubit.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('TourListState bölümleri', () {
    final state = TourListState(
      status: TourListStatus.ready,
      tours: [
        tourWith(id: '1', title: 'Yerköprü Şelalesi', region: TourRegion.dayTrip),
        tourWith(id: '2', title: 'Kapadokya', region: TourRegion.centralAnatolia),
        tourWith(id: '3', title: 'Gaziantep Lezzet', region: TourRegion.dayTrip),
        tourWith(id: '4', title: 'Uzungöl', region: TourRegion.blackSea, companyName: 'Rize Tur'),
      ],
    );

    test('turlar bölge sırasına göre gruplanır, boş bölge çıkmaz', () {
      final sections = state.sections;
      expect(sections.map((section) => section.region), [
        TourRegion.blackSea,
        TourRegion.centralAnatolia,
        TourRegion.dayTrip,
      ]);
      expect(sections.last.tours.map((tour) => tour.id), ['1', '3']);
    });

    test('arama başlıkta ve firma adında yapılır', () {
      expect(state.copyWith(query: 'kapadokya').sections.single.tours.single.id, '2');
      expect(state.copyWith(query: 'rize').sections.single.tours.single.id, '4');
      expect(state.copyWith(query: 'yerkopru').sections.single.tours.single.id, '1');
      expect(state.copyWith(query: 'olmayan').sections, isEmpty);
    });
  });

  test('TourModel önbellek biçimi aynen geri okunur', () {
    final tour = tourWith(departures: [DateTime.utc(2030, 5, 1, 7), DateTime.utc(2030, 5, 8, 7)]);

    final restored = TourModel.fromRow(TourModel.toRow(tour));

    expect(restored, tour);
  });

  test('LoginId e-postaya büyük/küçük harf ve boşluk farkı olmadan çevrilir', () {
    expect(LoginId.toEmail(' reh-1234 '), 'reh-1234@${LoginId.emailDomain}');
    expect(LoginId.toEmail('REH-1234'), LoginId.toEmail('reh-1234'));
    expect(LoginId.looksLikeLoginId('REH-1234'), isTrue);
    expect(LoginId.looksLikeLoginId('ali@example.com'), isFalse);
  });
}
