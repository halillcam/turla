import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/feedback_item.dart';
import '../../domain/repositories/feedback_repository.dart';

/// Geri bildirimler. [companyId] verilirse firma alanı (firma admini gönderir);
/// verilmezse super admin tüm firmalarınkini görür ve durumunu değiştirir.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit({required this.companyId, required this._repository})
    : super(const FeedbackState());

  final String? companyId;
  final FeedbackRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      emit(
        FeedbackState(
          status: LoadStatus.ready,
          items: await _repository.list(companyId: companyId),
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<FeedbackItem>> send({required String title, required String body}) async {
    final id = companyId;
    if (id == null) return const ActionResult.failed(PanelFailureReason.notAllowed);
    final result = await runAction(() => _repository.send(companyId: id, title: title, body: body));
    final created = result.value;
    if (created != null) emit(state.copyWith(items: [created, ...state.items]));
    return result;
  }

  Future<ActionResult<FeedbackItem>> setStatus(FeedbackItem item, FeedbackStatus status) async {
    final result = await runAction(() => _repository.setStatus(item, status));
    final updated = result.value;
    if (updated != null) {
      emit(state.copyWith(items: [for (final i in state.items) i.id == updated.id ? updated : i]));
    }
    return result;
  }
}

final class FeedbackState extends Equatable {
  const FeedbackState({this.status = LoadStatus.initial, this.items = const [], this.loadFailure});

  final LoadStatus status;
  final List<FeedbackItem> items;
  final PanelFailureReason? loadFailure;

  FeedbackState copyWith({
    LoadStatus? status,
    List<FeedbackItem>? items,
    PanelFailureReason? loadFailure,
  }) => FeedbackState(
    status: status ?? this.status,
    items: items ?? this.items,
    loadFailure: loadFailure ?? this.loadFailure,
  );

  @override
  List<Object?> get props => [status, items, loadFailure];
}
