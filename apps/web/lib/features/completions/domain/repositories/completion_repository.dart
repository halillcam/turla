import '../entities/completion_request.dart';

/// Tur bitirme talepleri. Hatalar `PanelFailure` olarak fırlatılır.
abstract interface class CompletionRepository {
  /// Firmanın son talepleri (en yeni önce, en fazla [limit] adet).
  Future<List<CompletionRequest>> listRequests(String companyId, {int limit});

  /// `review_departure_completion` ile onaylar veya reddeder.
  Future<CompletionRequest> review(CompletionRequest request, {required bool approve});
}
