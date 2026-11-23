import '../entities/sign_up_result.dart';
import '../entities/user_profile.dart';

/// Oturum ve profil işlemleri. Hatalar [AuthFailure] olarak fırlatılır.
abstract interface class AuthRepository {
  /// Oturum açıldığında, kapandığında veya yenilendiğinde tetiklenir.
  Stream<void> get authStateChanges;

  /// Oturumdaki kullanıcının profili; oturum yoksa null.
  Future<UserProfile?> currentProfile();

  Future<UserProfile> signInWithEmail({required String email, required String password});

  /// Panelden açılan hesaplar için (rehber, dışarıdan eklenen müşteri).
  Future<UserProfile> signInWithLoginId({required String loginId, required String password});

  /// Mobil uygulamadan müşteri kaydı.
  Future<SignUpResult> signUpCustomer({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Oturumdaki kullanıcının seçili ilini profiline yazar.
  Future<void> updateSelectedCity(int cityId);
}
