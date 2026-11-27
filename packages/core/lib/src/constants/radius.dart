import 'package:flutter/painting.dart';

/// Köşe yuvarlaklıkları (Stitch: sm 4, varsayılan 10, md 12, lg 16, xl 24).
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 10;
  static const double mdPlus = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  /// Web paneli: düğme/giriş alanı 8, kart/tablo 12.
  static const double panelControl = 8;
  static const BorderRadius panelControlAll = BorderRadius.all(Radius.circular(panelControl));

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius mdPlusAll = BorderRadius.all(Radius.circular(mdPlus));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Alttan açılan paneller (bottom sheet) için üst köşeler.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
