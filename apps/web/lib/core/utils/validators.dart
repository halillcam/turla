import '../constants/strings.dart';

/// Form alanı doğrulayıcıları. Hata metni döner, geçerliyse null.
abstract final class Validators {
  static const int minPasswordLength = 8;
  static const int minNameLength = 3;
  static const int maxPhoneLength = 20;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _price = RegExp(r'^\d{1,8}([.,]\d{1,2})?$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null;

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.fieldRequired;
    return _email.hasMatch(text) ? null : AppStrings.invalidEmail;
  }

  static String? password(String? value) =>
      (value ?? '').length < minPasswordLength ? AppStrings.passwordTooShort : null;

  static String? name(String? value) =>
      (value?.trim().length ?? 0) < minNameLength ? AppStrings.nameTooShort : null;

  static String? title(String? value) =>
      (value?.trim().length ?? 0) < minNameLength ? AppStrings.titleTooShort : null;

  static String? optionalPhone(String? value) =>
      (value?.trim().length ?? 0) > maxPhoneLength ? AppStrings.phoneTooLong : null;

  static String? price(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.fieldRequired;
    return _price.hasMatch(text) ? null : AppStrings.invalidPrice;
  }

  static String? capacity(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return AppStrings.invalidNumber;
    return parsed < 1 ? AppStrings.capacityMustBePositive : null;
  }

  /// "750,50" → 750.5 (önce [price] ile doğrulanmalıdır).
  static double parsePrice(String value) => double.parse(value.trim().replaceAll(',', '.'));

  /// Boş metni null'a çevirir.
  static String? nullIfBlank(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
