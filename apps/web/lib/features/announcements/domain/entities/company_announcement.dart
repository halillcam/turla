import 'package:equatable/equatable.dart';

/// Super admin'in firmalara panel duyurusu. [companyId] null ise tüm firmalara.
class CompanyAnnouncement extends Equatable {
  const CompanyAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.companyId,
    this.companyName,
  });

  static const int titleMinLength = 3;
  static const int titleMaxLength = 160;
  static const int bodyMaxLength = 4000;

  final String id;
  final String? companyId;

  /// Hedef firmanın adı (tüm firmalara ise null).
  final String? companyName;
  final String title;
  final String body;
  final DateTime createdAt;

  bool get isForAllCompanies => companyId == null;

  @override
  List<Object?> get props => [id, companyId, companyName, title, body, createdAt];
}
