import 'package:turla_core/turla_core.dart';

/// Cihaz token'ının sunucu kaydı (`device_tokens`).
abstract interface class DeviceTokenRemoteDataSource {
  bool get isSignedIn;

  /// `register_device_token`: aynı telefonda hesap değişince token yeni hesaba geçer.
  Future<void> register(String token, String platform);

  /// Kullanıcı kendi token'ını siler (RLS).
  Future<void> remove(String token);
}

class DeviceTokenRemoteDataSourceImpl implements DeviceTokenRemoteDataSource {
  const DeviceTokenRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  Future<void> register(String token, String platform) => _client.rpc<void>(
    'register_device_token',
    params: {'p_token': token, 'p_platform': platform},
  );

  @override
  Future<void> remove(String token) => _client.from('device_tokens').delete().eq('token', token);
}
