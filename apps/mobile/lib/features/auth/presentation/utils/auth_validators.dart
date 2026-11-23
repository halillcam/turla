import '../../../../core/constants/strings.dart';

/// Form alanı doğrulayıcıları. Hata varsa mesajı, yoksa null döner.
abstract final class AuthValidators {
  static const int minPasswordLength = 8;
  static const int minFullNameLength = 3;
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null;

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return _email.hasMatch(value!.trim()) ? null : AppStrings.invalidEmail;
  }

  static String? newPassword(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return value!.length < minPasswordLength ? AppStrings.passwordTooShort : null;
  }

  static String? fullName(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return value!.trim().length < minFullNameLength ? AppStrings.fullNameTooShort : null;
  }

  static String? Function(String?) passwordConfirmation(String Function() password) =>
      (value) => value == password() ? null : AppStrings.passwordsDoNotMatch;
}
