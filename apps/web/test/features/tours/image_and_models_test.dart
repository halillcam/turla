import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/completions/data/repositories/completion_repository_impl.dart';
import 'package:turla_web/features/completions/domain/entities/completion_request.dart';
import 'package:turla_web/features/tours/data/models/tour_admin_models.dart';
import 'package:turla_web/features/tours/data/repositories/tour_admin_repository_impl.dart';
import 'package:turla_web/features/tours/data/services/image_resizer.dart';
import 'package:turla_web/features/tours/domain/entities/departure.dart';
import 'package:turla_web/features/tours/domain/entities/program_day.dart';

void main() {
  group('ImageResizer', () {
    const resizer = ImageResizer();

    test('büyük görselin uzun kenarı 1280 px olur, oran korunur', () {
      final source = img.encodePng(img.Image(width: 2560, height: 1440));
      final out = img.decodeJpg(resizer.resizeToJpeg(source))!;
      expect(out.width, AppSizes.uploadImageMaxDimension);
      expect(out.height, 720);
    });

    test('dikey görselde yükseklik sınırlanır', () {
      final source = img.encodePng(img.Image(width: 1000, height: 3000));
      final out = img.decodeJpg(resizer.resizeToJpeg(source))!;
      expect(out.height, AppSizes.uploadImageMaxDimension);
      expect(out.width, 427);
    });

    test('küçük görsel büyütülmez, JPEG olur', () {
      final source = img.encodePng(img.Image(width: 400, height: 300));
      final out = img.decodeJpg(resizer.resizeToJpeg(source))!;
      expect((out.width, out.height), (400, 300));
    });

    test('görsel olmayan dosya reddedilir', () {
      expect(
        () => resizer.resizeToJpeg(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(
          isA<PanelFailure>().having((e) => e.reason, 'reason', PanelFailureReason.invalidImage),
        ),
      );
    });
  });

  group('görsel yolu', () {
    test('ilk klasör şirket kimliğidir (RLS kuralı)', () {
      final path = TourAdminRepositoryImpl.imagePath('c1', 't1', DateTime.utc(2026, 11, 24));
      expect(path, startsWith('c1/t1-'));
      expect(path, endsWith('.jpg'));
    });

    test('public URL\'den yol çıkarılır', () {
      expect(
        TourAdminRepositoryImpl.storagePathFromUrl(
          'https://x.supabase.co/storage/v1/object/public/tour-images/c1/t1-1.jpg',
        ),
        'c1/t1-1.jpg',
      );
      expect(TourAdminRepositoryImpl.storagePathFromUrl('https://baska.site/foto.jpg'), isNull);
      expect(TourAdminRepositoryImpl.storagePathFromUrl(null), isNull);
    });
  });

  group('modeller', () {
    test('tur listesinde tarih sayısı okunur', () {
      final tour = ManagedTourModel.fromRow({
        'id': 't1',
        'company_id': 'c1',
        'title': 'Göksun',
        'description': null,
        'extra_detail': null,
        'price': 750.5,
        'city_id': 46,
        'region': 'akdeniz',
        'image_url': null,
        'is_active': true,
        'tour_departures': [
          {'count': 3},
        ],
      });
      expect(tour.departureCount, 3);
      expect(tour.region, TourRegion.mediterranean);
      expect(tour.description, '');
    });

    test('tarih yazılırken UTC gönderilir, koltuk/durum gönderilmez, boş alanlar null', () {
      final row = DepartureModel.toRow(
        DepartureDraft(
          departureAt: DateTime.utc(2026, 12, 1, 5, 30),
          capacity: 20,
          busPlate: '  ',
          driverName: ' Ali ',
        ),
      );
      expect(row['departure_at'], '2026-12-01T05:30:00.000Z');
      expect(row.containsKey('seats_left'), isFalse);
      expect(row.containsKey('status'), isFalse);
      expect(row['bus_plate'], isNull);
      expect(row['driver_name'], 'Ali');
    });

    test('program günü JSON\'u boş etkinlikleri atar', () {
      final json = ProgramDayModel.toJson(
        const ProgramDay(title: ' Gün ', activities: ['a', ' ', ' b ']),
      );
      expect(json, {
        'title': 'Gün',
        'activities': ['a', 'b'],
      });
    });

    test('tur bitirme talebi iç içe satırdan okunur', () {
      final request = CompletionRepositoryImpl.fromRow({
        'id': 'r1',
        'departure_id': 'd1',
        'status': 'pending',
        'created_at': '2026-11-24T10:00:00Z',
        'reviewed_at': null,
        'guide': {'full_name': 'Rehber Rıza'},
        'departure': {
          'departure_at': '2026-11-23T05:00:00Z',
          'tour': {'title': 'Göksun'},
        },
      });
      expect(request.tourTitle, 'Göksun');
      expect(request.guideName, 'Rehber Rıza');
      expect(request.status, CompletionStatus.pending);
      expect(request.reviewedAt, isNull);
    });
  });
}
