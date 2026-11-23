/// Panelden açılan hesaplar (rehber, dışarıdan eklenen müşteri) e-posta yerine
/// bir giriş kimliğiyle (ör. `REH-4821`) giriş yapar. Supabase Auth e-posta
/// istediği için kimlik bu sabit alan adıyla e-postaya çevrilir. Bu adreslere
/// hiçbir zaman e-posta gönderilmez.
abstract final class LoginId {
  static const String emailDomain = 'staff.turla.app';

  /// Kullanıcının yazdığı kimliği giriş e-postasına çevirir (büyük/küçük harf
  /// ve boşluk farkı önemsizdir).
  static String toEmail(String loginId) => '${normalize(loginId).toLowerCase()}@$emailDomain';

  static String normalize(String loginId) => loginId.trim().toUpperCase();

  /// Girilen değer e-posta değilse giriş kimliği kabul edilir.
  static bool looksLikeLoginId(String value) => !value.contains('@');
}
