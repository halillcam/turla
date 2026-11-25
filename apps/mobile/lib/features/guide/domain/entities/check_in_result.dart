import 'package:equatable/equatable.dart';

/// `scan_ticket` / `check_in_manually` sonuç kodları.
enum CheckInCode {
  ok('ok'),
  notFound('not_found'),
  wrongDeparture('wrong_departure'),
  alreadyUsed('already_used'),
  cancelled('cancelled'),
  notPaid('not_paid');

  const CheckInCode(this.value);

  final String value;

  static CheckInCode fromValue(String? value) => CheckInCode.values.firstWhere(
    (code) => code.value == value,
    orElse: () => CheckInCode.notFound,
  );
}

/// Okutma / elle işaretleme sonucu.
class CheckInResult extends Equatable {
  const CheckInResult({required this.code, this.ticketId, this.passengerName, this.scannedAt});

  final CheckInCode code;
  final String? ticketId;
  final String? passengerName;

  /// Başarılıysa şimdi; "daha önce okutuldu" ise ilk okutma zamanı.
  final DateTime? scannedAt;

  bool get isSuccess => code == CheckInCode.ok;

  @override
  List<Object?> get props => [code, ticketId, passengerName, scannedAt];
}
