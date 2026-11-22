import '../../domain/entities/city.dart';

/// `cities` tablosunun satırı ve önbellekteki JSON karşılığı.
class CityModel {
  const CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) =>
      CityModel(id: (json[_idKey] as num).toInt(), name: json[_nameKey] as String);

  factory CityModel.fromEntity(City city) => CityModel(id: city.id, name: city.name);

  static const String _idKey = 'id';
  static const String _nameKey = 'name';

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {_idKey: id, _nameKey: name};

  City toEntity() => City(id: id, name: name);
}
