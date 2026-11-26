part of 'announcements_cubit.dart';

enum AnnouncementsStatus { loading, ready, failure }

final class AnnouncementsState extends Equatable {
  const AnnouncementsState({
    this.status = AnnouncementsStatus.loading,
    this.announcements = const [],
    this.isSending = false,
    this.sentCount = 0,
    this.failure,
    this.actionFailure,
  });

  final AnnouncementsStatus status;

  /// Yeniden eskiye.
  final List<Announcement> announcements;
  final bool isSending;

  /// Her başarılı gönderimde artar; ekran yazı kutusunu temizler ve mesaj gösterir.
  final int sentCount;
  final LiveTourFailureReason? failure;
  final LiveTourFailureReason? actionFailure;

  AnnouncementsState copyWith({
    AnnouncementsStatus? status,
    List<Announcement>? announcements,
    bool? isSending,
    int? sentCount,
    LiveTourFailureReason? failure,
    LiveTourFailureReason? actionFailure,
    bool clearActionFailure = false,
  }) => AnnouncementsState(
    status: status ?? this.status,
    announcements: announcements ?? this.announcements,
    isSending: isSending ?? this.isSending,
    sentCount: sentCount ?? this.sentCount,
    failure: failure ?? this.failure,
    actionFailure: clearActionFailure ? null : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [status, announcements, isSending, sentCount, failure, actionFailure];
}
