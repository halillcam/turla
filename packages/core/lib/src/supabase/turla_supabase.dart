import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Supabase bağlantısını başlatır ve istemciye tek noktadan erişim sağlar.
abstract final class TurlaSupabase {
  static Future<void> initialize() async {
    if (!Env.isConfigured) {
      throw const MissingEnvException();
    }
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

/// `.env` değerleri tanımlı değilse fırlatılır.
class MissingEnvException implements Exception {
  const MissingEnvException();
}
