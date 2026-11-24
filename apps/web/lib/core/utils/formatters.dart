import 'package:intl/intl.dart';

/// Para ve tarih biçimleri (Türkçe).
abstract final class Formatters {
  static const String _locale = 'tr_TR';

  static final NumberFormat _price = NumberFormat.currency(
    locale: _locale,
    symbol: '₺',
    decimalDigits: 2,
  );
  static final DateFormat _dateTime = DateFormat('d MMM y, HH:mm', _locale);
  static final DateFormat _date = DateFormat('d MMMM y', _locale);
  static final DateFormat _time = DateFormat('HH:mm', _locale);

  /// 750.5 → "₺750,50"
  static String price(double value) => _price.format(value);

  /// "12 Ara 2026, 08:30"
  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  /// "12 Aralık 2026"
  static String date(DateTime value) => _date.format(value.toLocal());

  /// "08:30"
  static String time(DateTime value) => _time.format(value.toLocal());

  /// Form alanı için fiyat: 750.0 → "750", 750.5 → "750,50"
  static String priceInput(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceAll('.', ',');
}
