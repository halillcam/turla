import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Panelde yönetilen tur (`tours` tablosu).
class ManagedTour extends Equatable {
  const ManagedTour({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.extraDetail,
    required this.price,
    required this.cityId,
    required this.region,
    required this.isActive,
    this.imageUrl,
    this.departureCount = 0,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String extraDetail;
  final double price;
  final int cityId;
  final TourRegion region;
  final bool isActive;
  final String? imageUrl;

  /// Listede gösterilen tarih sayısı.
  final int departureCount;

  TourDraft toDraft() => TourDraft(
    title: title,
    description: description,
    extraDetail: extraDetail,
    price: price,
    cityId: cityId,
    region: region,
    isActive: isActive,
  );

  @override
  List<Object?> get props => [
    id,
    companyId,
    title,
    description,
    extraDetail,
    price,
    cityId,
    region,
    isActive,
    imageUrl,
    departureCount,
  ];
}

/// Tur oluşturma / düzenleme formunun verisi.
class TourDraft extends Equatable {
  const TourDraft({
    required this.title,
    required this.price,
    required this.cityId,
    required this.region,
    this.description = '',
    this.extraDetail = '',
    this.isActive = true,
  });

  final String title;
  final String description;
  final String extraDetail;
  final double price;
  final int cityId;
  final TourRegion region;
  final bool isActive;

  @override
  List<Object?> get props => [title, description, extraDetail, price, cityId, region, isActive];
}
