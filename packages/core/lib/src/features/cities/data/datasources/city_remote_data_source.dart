import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/city_model.dart';

/// İlleri Supabase'deki `cities` tablosundan okur.
abstract interface class CityRemoteDataSource {
  Future<List<CityModel>> fetchCities();
}

class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  const CityRemoteDataSourceImpl(this._client);

  static const String _table = 'cities';
  static const String _columns = 'id, name';
  static const String _orderColumn = 'id';

  final SupabaseClient _client;

  @override
  Future<List<CityModel>> fetchCities() async {
    final rows = await _client.from(_table).select(_columns).order(_orderColumn, ascending: true);
    return rows.map(CityModel.fromJson).toList();
  }
}
