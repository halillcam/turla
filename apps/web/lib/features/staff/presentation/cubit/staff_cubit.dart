import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../domain/entities/new_account.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/account_repository.dart';

/// Firmanın tur sorumluları ve dışarıdan eklenen müşterileri.
class StaffCubit extends Cubit<StaffState> {
  StaffCubit({required this.companyId, required AccountRepository accountRepository})
    : _accounts = accountRepository,
      super(const StaffState());

  /// Panelden açılabilen roller.
  static const List<UserRole> managedRoles = [UserRole.guide, UserRole.customer];

  final String companyId;
  final AccountRepository _accounts;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final members = await _accounts.listMembers(companyId, roles: managedRoles);
      emit(StaffState(status: LoadStatus.ready, members: members));
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<CreatedAccount>> create({
    required UserRole role,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    assert(managedRoles.contains(role), 'Panelden sadece rehber ve müşteri açılır.');
    return _busy(() async {
      final created = await _accounts.createAccount(
        NewAccount(
          role: role,
          companyId: companyId,
          fullName: fullName,
          password: password,
          phone: phone,
        ),
      );
      final member = StaffMember(
        id: created.userId,
        fullName: fullName.trim(),
        role: role,
        isActive: true,
        loginId: created.loginId,
        phone: phone,
      );
      emit(state.copyWith(members: [...state.members, member]));
      return created;
    });
  }

  Future<ActionResult<void>> toggleActive(StaffMember member) => _busy(() async {
    await _accounts.setActive(member.id, isActive: !member.isActive);
    emit(
      state.copyWith(
        members: [
          for (final m in state.members)
            m.id == member.id ? m.copyWith(isActive: !member.isActive) : m,
        ],
      ),
    );
  });

  /// Yeni geçici şifre; liste değişmez, yeniden istek atılmaz.
  Future<ActionResult<String>> resetPassword(StaffMember member) =>
      _busy(() => _accounts.resetPassword(member.id));

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }
}

final class StaffState extends Equatable {
  const StaffState({
    this.status = LoadStatus.initial,
    this.members = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<StaffMember> members;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  List<StaffMember> get guides => members.where((m) => m.role == UserRole.guide).toList();
  List<StaffMember> get customers => members.where((m) => m.role == UserRole.customer).toList();

  StaffState copyWith({
    LoadStatus? status,
    List<StaffMember>? members,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => StaffState(
    status: status ?? this.status,
    members: members ?? this.members,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, members, loadFailure, isBusy];
}
