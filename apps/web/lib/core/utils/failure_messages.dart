import 'package:turla_core/turla_core.dart';

import '../constants/strings.dart';
import '../../features/auth/domain/panel_session.dart';
import '../errors/panel_failure.dart';

/// Hata türlerini kullanıcıya gösterilecek metne çevirir.
extension PanelFailureMessage on PanelFailureReason {
  String get message => switch (this) {
    PanelFailureReason.network => CoreStrings.networkError,
    PanelFailureReason.notAllowed => AppStrings.errorNotAllowed,
    PanelFailureReason.notFound => AppStrings.errorNotFound,
    PanelFailureReason.companyInactive => AppStrings.errorCompanyInactive,
    PanelFailureReason.hasTickets => AppStrings.errorHasTickets,
    PanelFailureReason.capacityBelowSoldSeats => AppStrings.errorCapacityBelowSold,
    PanelFailureReason.invalidGuide => AppStrings.errorInvalidGuide,
    PanelFailureReason.alreadyReviewed => AppStrings.errorAlreadyReviewed,
    PanelFailureReason.emailExists => AppStrings.errorEmailExists,
    PanelFailureReason.weakPassword => AppStrings.errorWeakPassword,
    PanelFailureReason.invalidInput => AppStrings.errorInvalidInput,
    PanelFailureReason.cannotChangeSelf => AppStrings.errorCannotChangeSelf,
    PanelFailureReason.invalidImage => AppStrings.errorInvalidImage,
    PanelFailureReason.invalidCustomer => AppStrings.errorInvalidCustomer,
    PanelFailureReason.alreadyHasTicket => AppStrings.errorAlreadyHasTicket,
    PanelFailureReason.noSeatsLeft => AppStrings.errorNoSeatsLeft,
    PanelFailureReason.departureNotBookable => AppStrings.errorDepartureNotBookable,
    PanelFailureReason.ticketNotCancellable => AppStrings.errorTicketNotCancellable,
    PanelFailureReason.departureNotCancellable => AppStrings.errorDepartureNotCancellable,
    PanelFailureReason.notResettable => AppStrings.errorNotResettable,
    PanelFailureReason.rateLimited => AppStrings.errorChatRateLimited,
    PanelFailureReason.unknown => CoreStrings.unexpectedError,
  };
}

extension PanelDenialMessage on PanelDenial {
  String get message => switch (this) {
    PanelDenial.roleNotAllowed => AppStrings.errorRoleNotAllowed,
    PanelDenial.companyInactive => AppStrings.errorCompanyInactive,
  };
}

extension AuthFailureMessage on AuthFailureReason {
  String get message => switch (this) {
    AuthFailureReason.invalidCredentials => AppStrings.errorInvalidCredentials,
    AuthFailureReason.emailNotConfirmed => AppStrings.errorEmailNotConfirmed,
    AuthFailureReason.rateLimited => AppStrings.errorRateLimited,
    AuthFailureReason.network => CoreStrings.networkError,
    AuthFailureReason.accountDisabled => AppStrings.errorAccountDisabled,
    AuthFailureReason.profileMissing => AppStrings.errorProfileMissing,
    AuthFailureReason.roleNotAllowed => AppStrings.errorRoleNotAllowed,
    AuthFailureReason.userAlreadyExists ||
    AuthFailureReason.weakPassword ||
    AuthFailureReason.samePassword ||
    AuthFailureReason.unknown => CoreStrings.unexpectedError,
  };
}
