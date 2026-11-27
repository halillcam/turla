import 'package:flutter_test/flutter_test.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/core/errors/panel_guard.dart';
import 'package:turla_web/core/utils/validators.dart';

void main() {
  group('SQL fonksiyon / PostgREST hataları', () {
    test('raise exception kodları mesajdan okunur', () {
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'capacity_below_sold_seats'),
        PanelFailureReason.capacityBelowSoldSeats,
      );
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'invalid_guide'),
        PanelFailureReason.invalidGuide,
      );
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'request_already_reviewed'),
        PanelFailureReason.alreadyReviewed,
      );
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'cannot_change_self'),
        PanelFailureReason.cannotChangeSelf,
      );
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'rate_limited'),
        PanelFailureReason.rateLimited,
      );
      expect(
        PanelErrorMapper.fromPostgrest('P0001', 'departure_not_cancellable'),
        PanelFailureReason.departureNotCancellable,
      );
    });

    test('Postgres kodları', () {
      expect(
        PanelErrorMapper.fromPostgrest('23503', 'violates foreign key'),
        PanelFailureReason.hasTickets,
      );
      expect(
        PanelErrorMapper.fromPostgrest('42501', 'new row violates row-level security'),
        PanelFailureReason.notAllowed,
      );
      expect(PanelErrorMapper.fromPostgrest('PGRST116', 'no rows'), PanelFailureReason.notFound);
      expect(PanelErrorMapper.fromPostgrest('XX000', 'bilinmeyen'), PanelFailureReason.unknown);
    });
  });

  group('Edge Function hataları', () {
    test('gövdedeki code kullanılır', () {
      expect(
        PanelErrorMapper.fromFunction(409, {'code': 'email_exists'}),
        PanelFailureReason.emailExists,
      );
      expect(
        PanelErrorMapper.fromFunction(403, {'code': 'company_inactive'}),
        PanelFailureReason.companyInactive,
      );
      expect(
        PanelErrorMapper.fromFunction(400, {'code': 'weak_password'}),
        PanelFailureReason.weakPassword,
      );
      expect(
        PanelErrorMapper.fromFunction(400, {'code': 'not_resettable'}),
        PanelFailureReason.notResettable,
      );
      expect(
        PanelErrorMapper.fromFunction(404, {'code': 'account_not_found'}),
        PanelFailureReason.notFound,
      );
    });

    test('kod yoksa duruma göre', () {
      expect(PanelErrorMapper.fromFunction(401, null), PanelFailureReason.notAllowed);
      expect(PanelErrorMapper.fromFunction(400, 'metin'), PanelFailureReason.invalidInput);
      expect(PanelErrorMapper.fromFunction(500, {}), PanelFailureReason.unknown);
    });
  });

  test('guardPanel PanelFailure dışındaki hataları değiştirmez', () async {
    await expectLater(
      guardPanel<void>(() async => throw const PanelFailure(PanelFailureReason.notFound)),
      throwsA(isA<PanelFailure>().having((e) => e.reason, 'reason', PanelFailureReason.notFound)),
    );
  });

  group('form doğrulama', () {
    test('fiyat', () {
      expect(Validators.price('750'), isNull);
      expect(Validators.price('750,50'), isNull);
      expect(Validators.price('750.5'), isNull);
      expect(Validators.price('7,505'), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.parsePrice(' 750,50 '), 750.5);
    });

    test('kontenjan ve şifre', () {
      expect(Validators.capacity('0'), isNotNull);
      expect(Validators.capacity('12'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });
}
