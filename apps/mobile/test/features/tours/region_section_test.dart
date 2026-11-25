import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/core/constants/strings.dart';
import 'package:turla_mobile/features/tours/presentation/cubit/tour_list_cubit.dart';
import 'package:turla_mobile/features/tours/presentation/widgets/region_section_view.dart';
import 'package:turla_mobile/features/tours/presentation/widgets/tour_card.dart';

import '../../helpers/fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  final tours = [
    tourWith(id: '1', title: 'Yerköprü Şelalesi', region: TourRegion.dayTrip),
    tourWith(id: '2', title: 'Kapadokya', region: TourRegion.centralAnatolia),
    tourWith(id: '3', title: 'Gaziantep Lezzet', region: TourRegion.dayTrip),
    tourWith(id: '4', title: 'Ahır Dağı Yürüyüşü', region: TourRegion.dayTrip),
  ];

  test('bölge süzmesi sadece o bölgenin turlarını bırakır', () {
    final state = TourListState(
      status: TourListStatus.ready,
      tours: tours,
      region: TourRegion.dayTrip,
    );
    expect(state.sections.single.region, TourRegion.dayTrip);
    expect(state.visibleTours.map((tour) => tour.id), ['1', '3', '4']);
    expect(state.copyWith(query: 'gaziantep').visibleTours.single.id, '3');
  });

  test('bölge süzmesi yokken tüm bölgeler tek listede sırayla gelir', () {
    final state = TourListState(status: TourListStatus.ready, tours: tours);
    expect(state.visibleTours.map((tour) => tour.id), ['2', '1', '3', '4']);
  });

  testWidgets('bölge turları yatay kayar, sonraki kart sağdan görünür, Tümünü gör çalışır', (
    tester,
  ) async {
    var seeAllTapped = false;
    final section = RegionSection(
      region: TourRegion.dayTrip,
      tours: tours.where((tour) => tour.region == TourRegion.dayTrip).toList(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionSectionView(
            section: section,
            onTourTap: (_) {},
            onSeeAll: () => seeAllTapped = true,
          ),
        ),
      ),
    );

    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(find.text(TourRegion.dayTrip.label.toUpperCase()), findsOneWidget);

    // 800 px genişlikte ilk iki kart (280 + 12 + 280) ekranda; ikinci kart da görünür.
    final firstCard = tester.getRect(find.byType(TourCard).first);
    expect(firstCard.width, AppSizes.tourCarouselCardWidth);
    final secondCard = tester.getRect(find.byType(TourCard).at(1));
    expect(secondCard.left, lessThan(800));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.seeAll));
    expect(seeAllTapped, isTrue);
  });
}
