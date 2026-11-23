/// Giriş / kayıt işlemlerinde oluşabilecek hata türleri.
/// Arayüz bu türü kullanıcıya gösterilecek mesaja çevirir.
enum AuthFailureReason {
  invalidCredentials,
  emailNotConfirmed,
  userAlreadyExists,
  weakPassword,
  rateLimited,
  network,
  accountDisabled,
  profileMissing,
  roleNotAllowed,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason, [this.cause]);

  final AuthFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'AuthFailure($reason, $cause)';
}
