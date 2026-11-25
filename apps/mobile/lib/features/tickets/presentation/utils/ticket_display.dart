import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/ticket.dart';
import '../screens/checkout_screen.dart';

/// Biletin ekranda gösterilecek metinleri.
extension TicketDisplay on Ticket {
  /// "12 Aralık 2026, Cumartesi · 08:30"
  String get departureLabel => '${Formatters.date(departureAt)} · ${Formatters.time(departureAt)}';

  /// "12 Ara 08:30"
  String get shortDepartureLabel =>
      '${Formatters.shortDate(departureAt)} ${Formatters.time(departureAt)}';

  /// "Son iptal: 12 Ara 07:30"
  String get cancelDeadlineLabel =>
      '${AppStrings.cancelDeadlinePrefix}: '
      '${Formatters.shortDate(cancellationDeadline)} ${Formatters.time(cancellationDeadline)}';

  /// İptal penceresindeki iade metni.
  String get refundPreviewLabel => pricePaid > 0
      ? '${AppStrings.cancelDialogRefundPrefix} ${Formatters.price(pricePaid)}'
      : AppStrings.cancelDialogFreeTour;

  /// İptal onay penceresi: tur, tarih ve iade tutarı.
  String get cancelDialogMessage => '$tourTitle\n$departureLabel\n\n$refundPreviewLabel';

  /// İptal edilmiş biletin iade tutarı, ör. "₺1.850" (ücretsizse null).
  String? get refundLabel {
    final amount = refundAmount;
    return amount == null ? null : Formatters.price(amount);
  }

  /// "12 Ara 14:05" (iptal edilmediyse null).
  String? get cancelledAtLabel {
    final at = cancelledAt;
    return at == null ? null : '${Formatters.shortDate(at)} ${Formatters.time(at)}';
  }

  /// Tur sorumlusu okuttu: QR yerine "QR kodun okutuldu" gösterilir.
  bool get showsScannedNotice => status == TicketStatus.checkedIn;

  /// "QR kodun okutuldu · 08:12"
  String get scannedLabel {
    final at = scannedAt;
    return at == null
        ? AppStrings.qrScannedTitle
        : '${AppStrings.qrScannedTitle} · ${Formatters.time(at)}';
  }

  /// QR sadece kullanılmamış geçerli bilette gösterilir.
  bool get showsQr => isActive && status.isUpcoming;

  /// "46 ABC 101" veya "Belirtilmedi"
  String get vehicleLabel => _orNotSpecified(busPlate);

  String get driverLabel => _orNotSpecified(driverName);

  String get companyPhoneLabel => _orNotSpecified(companyPhone);

  String _orNotSpecified(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.notSpecified : value;
}

/// Satın alma ekranındaki tur özetinin metinleri.
extension CheckoutArgsDisplay on CheckoutArgs {
  String get departureLabel => '${Formatters.date(departureAt)} · ${Formatters.time(departureAt)}';

  String get priceLabel => Formatters.price(price);
}
