import 'package:intl/intl.dart';

/// Para ve tarih biçimleri (Türkçe).
abstract final class Formatters {
  static const String _locale = 'tr_TR';

  static final NumberFormat _price = NumberFormat.currency(
    locale: _locale,
    symbol: '₺',
    decimalDigits: 2,
  );
  static final NumberFormat _wholePrice = NumberFormat.currency(
    locale: _locale,
    symbol: '₺',
    decimalDigits: 0,
  );
  static final DateFormat _date = DateFormat('d MMMM y, EEEE', _locale);
  static final DateFormat _shortDate = DateFormat('d MMM', _locale);
  static final DateFormat _time = DateFormat('HH:mm', _locale);

  /// 750 → "₺750", 750.5 → "₺750,50"
  static String price(double value) =>
      value == value.roundToDouble() ? _wholePrice.format(value) : _price.format(value);

  /// "12 Aralık 2026, Cumartesi"
  static String date(DateTime value) => _date.format(value.toLocal());

  /// "12 Ara"
  static String shortDate(DateTime value) => _shortDate.format(value.toLocal());

  /// "08:30"
  static String time(DateTime value) => _time.format(value.toLocal());
}
