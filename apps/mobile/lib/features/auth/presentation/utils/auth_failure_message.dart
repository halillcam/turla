import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';

/// Hata türünü kullanıcıya gösterilecek metne çevirir.
extension AuthFailureMessage on AuthFailureReason {
  String get message => switch (this) {
    AuthFailureReason.invalidCredentials => AppStrings.errorInvalidCredentials,
    AuthFailureReason.emailNotConfirmed => AppStrings.errorEmailNotConfirmed,
    AuthFailureReason.userAlreadyExists => AppStrings.errorUserAlreadyExists,
    AuthFailureReason.weakPassword => AppStrings.errorWeakPassword,
    AuthFailureReason.samePassword => AppStrings.errorSamePassword,
    AuthFailureReason.rateLimited => AppStrings.errorRateLimited,
    AuthFailureReason.network => CoreStrings.networkError,
    AuthFailureReason.accountDisabled => AppStrings.errorAccountDisabled,
    AuthFailureReason.profileMissing => AppStrings.errorProfileMissing,
    AuthFailureReason.roleNotAllowed => AppStrings.errorRoleNotAllowed,
    AuthFailureReason.unknown => CoreStrings.unexpectedError,
  };
}
