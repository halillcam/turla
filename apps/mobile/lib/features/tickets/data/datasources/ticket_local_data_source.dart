import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/ticket.dart';
import '../models/ticket_model.dart';

/// Biletleri kullanıcı bazında cihazda saklar (QR internetsiz açılsın diye).
abstract interface class TicketLocalDataSource {
  /// Kayıt yoksa veya biçimi eskiyse null.
  Future<List<Ticket>?> read(String userId);

  Future<void> write(String userId, List<Ticket> tickets);
}

class TicketLocalDataSourceImpl implements TicketLocalDataSource {
  TicketLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _versionKey = 'version';
  static const String _ticketsKey = 'tickets';

  final SharedPreferencesAsync _preferences;

  String _key(String userId) => '${StorageKeys.ticketsByUserPrefix}$userId';

  @override
  Future<List<Ticket>?> read(String userId) async {
    final raw = await _preferences.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json[_versionKey] != CacheVersions.tickets) return null;
      return (json[_ticketsKey] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TicketModel.fromRow)
          .toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(String userId, List<Ticket> tickets) => _preferences.setString(
    _key(userId),
    jsonEncode({
      _versionKey: CacheVersions.tickets,
      _ticketsKey: tickets.map(TicketModel.toRow).toList(),
    }),
  );
}
