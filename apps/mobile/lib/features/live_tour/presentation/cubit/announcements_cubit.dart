import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/entities/live_tour_failure.dart';
import '../../domain/repositories/announcement_repository.dart';

part 'announcements_state.dart';

/// Bir tarihin duyuruları; tur sorumlusu buradan duyuru da gönderir.
/// Gönderilen duyuru listeye yerelde eklenir (liste yeniden çekilmez).
class AnnouncementsCubit extends Cubit<AnnouncementsState> {
  AnnouncementsCubit(this._repository) : super(const AnnouncementsState());

  final AnnouncementRepository _repository;
  String? _departureId;

  Future<void> load(String departureId) async {
    _departureId = departureId;
    emit(AnnouncementsState(announcements: state.announcements));
    try {
      final list = await _repository.fetchAnnouncements(departureId);
      if (isClosed) return;
      emit(state.copyWith(status: AnnouncementsStatus.ready, announcements: list));
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(status: AnnouncementsStatus.failure, failure: failure.reason));
    }
  }

  Future<void> retry() async {
    final departureId = _departureId;
    if (departureId != null) await load(departureId);
  }

  Future<void> send(String body) async {
    final departureId = _departureId;
    final text = body.trim();
    if (departureId == null || text.isEmpty || state.isSending) return;
    emit(state.copyWith(isSending: true, clearActionFailure: true));
    try {
      final announcement = await _repository.sendAnnouncement(departureId, text);
      if (isClosed) return;
      emit(
        state.copyWith(
          isSending: false,
          announcements: [announcement, ...state.announcements],
          sentCount: state.sentCount + 1,
        ),
      );
    } on LiveTourFailure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(isSending: false, actionFailure: failure.reason));
    }
  }
}
