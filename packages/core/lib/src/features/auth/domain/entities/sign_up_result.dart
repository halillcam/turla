import 'user_profile.dart';

/// Kayıt sonucu. E-posta doğrulaması açıksa oturum açılmaz ve [profile] null olur.
class SignUpResult {
  const SignUpResult.signedIn(UserProfile this.profile) : requiresEmailConfirmation = false;

  const SignUpResult.confirmationRequired() : profile = null, requiresEmailConfirmation = true;

  final UserProfile? profile;
  final bool requiresEmailConfirmation;
}
