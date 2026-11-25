part of 'departure_cubit.dart';

enum DepartureViewStatus { loading, ready, failure, notFound }

/// Ekrandaki tek seferlik işlemin durumu (elle "Geldi", "Turu bitir").
enum DepartureAction { idle, inProgress, completionRequested, failure }

enum ParticipantFilter { all, arrived, notArrived }

final class DepartureState extends Equatable {
  const DepartureState({
    this.status = DepartureViewStatus.loading,
    this.departure,
    this.participants = const [],
    this.filter = ParticipantFilter.all,
    this.query = '',
    this.isStale = false,
    this.canRequestCompletion = false,
    this.actionStatus = DepartureAction.idle,
    this.lastCheckIn,
    this.failure,
    this.actionFailure,
  });

  final DepartureViewStatus status;
  final GuideDeparture? departure;
  final List<Participant> participants;
  final ParticipantFilter filter;
  final String query;

  /// İnternet yokken cihazdaki son liste gösteriliyor.
  final bool isStale;

  /// Kalkış saati geldi ve tarih açık: "Turu bitir" gösterilir.
  final bool canRequestCompletion;
  final DepartureAction actionStatus;

  /// Son elle işaretlemenin sonucu (mesaj göstermek için).
  final CheckInResult? lastCheckIn;
  final GuideFailureReason? failure;
  final GuideFailureReason? actionFailure;

  int get arrivedCount => participants.where((participant) => participant.hasArrived).length;

  int get notArrivedCount => participants.length - arrivedCount;

  /// Filtre ve aramaya uyan katılımcılar: önce gelmeyenler, sonra ada göre.
  List<Participant> get visibleParticipants {
    final visible = participants.where((participant) {
      final matchesFilter = switch (filter) {
        ParticipantFilter.all => true,
        ParticipantFilter.arrived => participant.hasArrived,
        ParticipantFilter.notArrived => !participant.hasArrived,
      };
      return matchesFilter && SearchNormalizer.matches(participant.passengerName, query);
    }).toList();
    visible.sort((a, b) {
      if (a.hasArrived != b.hasArrived) return a.hasArrived ? 1 : -1;
      return a.passengerName.compareTo(b.passengerName);
    });
    return visible;
  }

  /// Okutma ve elle işaretleme açık mı?
  bool get canCheckIn => departure?.isActive ?? false;

  DepartureState copyWith({
    DepartureViewStatus? status,
    GuideDeparture? departure,
    List<Participant>? participants,
    ParticipantFilter? filter,
    String? query,
    bool? isStale,
    bool? canRequestCompletion,
    DepartureAction? actionStatus,
    CheckInResult? lastCheckIn,
    GuideFailureReason? failure,
    GuideFailureReason? actionFailure,
  }) => DepartureState(
    status: status ?? this.status,
    departure: departure ?? this.departure,
    participants: participants ?? this.participants,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    isStale: isStale ?? this.isStale,
    canRequestCompletion: canRequestCompletion ?? this.canRequestCompletion,
    actionStatus: actionStatus ?? this.actionStatus,
    lastCheckIn: lastCheckIn,
    failure: failure,
    actionFailure: actionFailure,
  );

  @override
  List<Object?> get props => [
    status,
    departure,
    participants,
    filter,
    query,
    isStale,
    canRequestCompletion,
    actionStatus,
    lastCheckIn,
    failure,
    actionFailure,
  ];
}
