import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_failure.dart';
import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/new_account.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._client);

  static const String _createAccountFunction = 'create-account';
  static const String _columns = 'id, full_name, role, is_active, login_id, phone';

  final SupabaseClient _client;

  @override
  Future<List<StaffMember>> listMembers(
    String companyId, {
    required List<UserRole> roles,
    bool activeOnly = false,
  }) => guardPanel(() async {
    var query = _client.from('profiles').select(_columns).eq('company_id', companyId).inFilter(
      'role',
      [for (final role in roles) role.value],
    );
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('full_name');
    return rows.map(_fromRow).toList();
  });

  @override
  Future<CreatedAccount> createAccount(NewAccount account) => guardPanel(() async {
    final response = await _client.functions.invoke(
      _createAccountFunction,
      body: {
        'role': account.role.value,
        'company_id': account.companyId,
        'full_name': account.fullName.trim(),
        'password': account.password,
        if (account.email != null) 'email': account.email!.trim(),
        if (account.phone != null) 'phone': account.phone!.trim(),
      },
    );
    final data = response.data;
    if (data is! Map || data['user_id'] is! String) {
      throw const PanelFailure(PanelFailureReason.unknown);
    }
    return CreatedAccount(
      userId: data['user_id'] as String,
      email: data['email'] as String,
      loginId: data['login_id'] as String?,
    );
  });

  @override
  Future<String> resetPassword(String profileId) => guardPanel(() async {
    final response = await _client.functions.invoke(
      _createAccountFunction,
      body: {'action': 'reset_password', 'user_id': profileId},
    );
    final data = response.data;
    if (data is! Map || data['password'] is! String) {
      throw const PanelFailure(PanelFailureReason.unknown);
    }
    return data['password'] as String;
  });

  @override
  Future<void> setActive(String profileId, {required bool isActive}) => guardPanel(() async {
    await _client.rpc<dynamic>(
      'set_profile_active',
      params: {'p_profile_id': profileId, 'p_active': isActive},
    );
  });

  static StaffMember _fromRow(Map<String, dynamic> row) => StaffMember(
    id: row['id'] as String,
    fullName: (row['full_name'] as String?) ?? '',
    role: UserRole.fromValue(row['role'] as String),
    isActive: (row['is_active'] as bool?) ?? true,
    loginId: row['login_id'] as String?,
    phone: row['phone'] as String?,
  );
}
