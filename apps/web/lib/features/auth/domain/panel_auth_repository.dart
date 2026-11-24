import 'panel_session.dart';

/// Panel oturumu. Sadece super admin ve aktif firmanın admini girebilir.
///
/// Hatalar: `AuthFailure` (kimlik / ağ) veya [PanelAccessDenied] (rol / pasif firma).
abstract interface class PanelAuthRepository {
  /// Oturum kapandığında (başka sekmede çıkış, token geçersiz) tetiklenir.
  Stream<void> get signedOut;

  /// Mevcut oturum; yoksa null.
  Future<PanelSession?> currentSession();

  Future<PanelSession> signIn({required String email, required String password});

  Future<void> signOut();
}
