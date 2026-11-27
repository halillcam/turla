import 'package:turla_core/turla_core.dart';

import '../entities/new_account.dart';
import '../entities/staff_member.dart';

/// Firma hesapları. Hatalar `PanelFailure` olarak fırlatılır.
abstract interface class AccountRepository {
  /// Firmanın verilen rollerdeki hesapları (ada göre sıralı).
  Future<List<StaffMember>> listMembers(
    String companyId, {
    required List<UserRole> roles,
    bool activeOnly = false,
  });

  /// `create-account` Edge Function'ı ile hesap açar.
  Future<CreatedAccount> createAccount(NewAccount account);

  /// `create-account` Edge Function'ının `reset_password` aksiyonu: giriş kimlikli
  /// hesaba (REH-/MUS-) yeni geçici şifre verir, şifreyi döndürür (bir kez gösterilir).
  Future<String> resetPassword(String profileId);

  /// `create-account` Edge Function'ının `admin_emails` aksiyonu (sadece super admin):
  /// firma yöneticilerinin e-postaları, profil kimliğine göre.
  Future<Map<String, String>> adminEmails(String companyId);

  /// `set_profile_active` ile hesabı aktif / pasif yapar.
  Future<void> setActive(String profileId, {required bool isActive});
}
