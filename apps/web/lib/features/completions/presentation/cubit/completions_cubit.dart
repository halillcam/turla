import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/completion_request.dart';
import '../../domain/repositories/completion_repository.dart';

/// Tur bitirme taleplerini listeler; onay/ret sunucu fonksiyonuyla yapılır.
class CompletionsCubit extends Cubit<CompletionsState> {
  CompletionsCubit({required this.companyId, required this._repository})
    : super(const CompletionsState());

  final String companyId;
  final CompletionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      emit(
        CompletionsState(
          status: LoadStatus.ready,
          requests: await _repository.listRequests(companyId),
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<CompletionRequest>> review(
    CompletionRequest request, {
    required bool approve,
  }) async {
    emit(state.copyWith(busyRequestId: request.id));
    final result = await runAction(() => _repository.review(request, approve: approve));
    final updated = result.value;
    emit(
      CompletionsState(
        status: state.status,
        requests: updated == null
            ? state.requests
            : [for (final r in state.requests) r.id == updated.id ? updated : r],
      ),
    );
    return result;
  }
}

final class CompletionsState extends Equatable {
  const CompletionsState({
    this.status = LoadStatus.initial,
    this.requests = const [],
    this.loadFailure,
    this.busyRequestId,
  });

  final LoadStatus status;
  final List<CompletionRequest> requests;
  final PanelFailureReason? loadFailure;

  /// İşlemi süren talep (butonları kilitlemek için).
  final String? busyRequestId;

  List<CompletionRequest> get pending => requests.where((r) => r.isPending).toList();
  List<CompletionRequest> get reviewed => requests.where((r) => !r.isPending).toList();

  CompletionsState copyWith({
    LoadStatus? status,
    List<CompletionRequest>? requests,
    PanelFailureReason? loadFailure,
    String? busyRequestId,
  }) => CompletionsState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    loadFailure: loadFailure ?? this.loadFailure,
    busyRequestId: busyRequestId ?? this.busyRequestId,
  );

  @override
  List<Object?> get props => [status, requests, loadFailure, busyRequestId];
}
