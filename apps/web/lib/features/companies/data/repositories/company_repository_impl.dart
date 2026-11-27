import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../models/company_model.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Company>> listCompanies() => guardPanel(() async {
    final rows = await _client
        .from(CompanyModel.table)
        .select(CompanyModel.columns)
        .order('name', ascending: true);
    return rows.map(CompanyModel.fromRow).toList();
  });

  @override
  Future<Company?> getCompany(String id) => guardPanel(() async {
    final row = await _client
        .from(CompanyModel.table)
        .select(CompanyModel.columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : CompanyModel.fromRow(row);
  });

  @override
  Future<Company> createCompany(CompanyDraft draft) => guardPanel(() async {
    final row = await _client
        .from(CompanyModel.table)
        .insert(CompanyModel.toRow(draft))
        .select(CompanyModel.columns)
        .single();
    return CompanyModel.fromRow(row);
  });

  @override
  Future<Company> updateCompany(String id, CompanyDraft draft) => guardPanel(() async {
    final row = await _client
        .from(CompanyModel.table)
        .update(CompanyModel.toRow(draft))
        .eq('id', id)
        .select(CompanyModel.columns)
        .single();
    return CompanyModel.fromRow(row);
  });

  @override
  Future<Company> setCompanyActive(String id, {required bool isActive}) => guardPanel(() async {
    final row = await _client
        .from(CompanyModel.table)
        .update({'is_active': isActive})
        .eq('id', id)
        .select(CompanyModel.columns)
        .single();
    return CompanyModel.fromRow(row);
  });
}
