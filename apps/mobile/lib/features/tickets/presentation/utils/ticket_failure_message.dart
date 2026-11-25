import 'package:turla_core/turla_core.dart';

import '../../../../core/constants/strings.dart';
import '../../domain/entities/ticket_failure.dart';

/// Bilet hata türünü kullanıcıya gösterilecek metne çevirir.
extension TicketFailureMessage on TicketFailureReason {
  String get message => switch (this) {
    TicketFailureReason.network => CoreStrings.networkError,
    TicketFailureReason.notSignedIn => AppStrings.errorNotSignedIn,
    TicketFailureReason.onlyCustomersCanBook => AppStrings.errorOnlyCustomersCanBook,
    TicketFailureReason.departureNotFound => AppStrings.errorDepartureNotFound,
    TicketFailureReason.tourNotAvailable => AppStrings.errorTourNotAvailable,
    TicketFailureReason.departureNotBookable => AppStrings.errorDepartureNotBookable,
    TicketFailureReason.alreadyHasTicket => AppStrings.errorAlreadyHasTicket,
    TicketFailureReason.noSeatsLeft => AppStrings.errorNoSeatsLeft,
    TicketFailureReason.ticketNotFound => AppStrings.errorTicketNotFound,
    TicketFailureReason.notAllowed => AppStrings.errorNotAllowed,
    TicketFailureReason.ticketNotCancellable => AppStrings.errorTicketNotCancellable,
    TicketFailureReason.cancellationWindowClosed => AppStrings.errorCancellationWindowClosed,
    TicketFailureReason.unknown => CoreStrings.unexpectedError,
  };
}
