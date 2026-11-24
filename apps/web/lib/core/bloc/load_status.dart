import '../errors/panel_failure.dart';

/// Ekran verisinin yüklenme durumu.
enum LoadStatus { initial, loading, ready, failure }

/// Kullanıcı işleminin (kaydet, sil, onayla ...) sonucu. Cubit metotları
/// bunu döndürür; ekran pencereyi kapatır veya hata mesajı gösterir.
class ActionResult<T> {
  const ActionResult.success([this.value]) : failure = null;

  const ActionResult.failed(PanelFailureReason this.failure) : value = null;

  final T? value;
  final PanelFailureReason? failure;

  bool get isSuccess => failure == null;
}

/// [action]'ı çalıştırır; `PanelFailure`'ı [ActionResult]'a çevirir.
Future<ActionResult<T>> runAction<T>(Future<T> Function() action) async {
  try {
    return ActionResult.success(await action());
  } on PanelFailure catch (failure) {
    return ActionResult.failed(failure.reason);
  }
}
