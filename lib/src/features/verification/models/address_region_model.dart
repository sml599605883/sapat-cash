import '../../../core/json/json.dart';

class AddressRegionModel {
  const AddressRegionModel({
    required this.name,
    required this.sort,
    required this.cities,
  });

  factory AddressRegionModel.fromJson(dynamic raw) {
    final json = raw is Json ? raw : Json(raw);
    return AddressRegionModel(
      name: json['fornices'].stringOrNull?.trim() ?? '',
      sort: json['braciole'].stringOrNull?.trim() ?? '',
      cities: json['noniron'].listValue
          .map((item) => AddressRegionModel.fromJson(item))
          .toList(growable: false),
    );
  }

  final String name;
  final String sort;
  final List<AddressRegionModel> cities;
}

class AddressSelectionResult {
  const AddressSelectionResult({
    required this.regionSort,
    required this.regionName,
    required this.citySort,
    required this.cityName,
    required this.areaSort,
    required this.areaName,
  });

  final String regionSort;
  final String regionName;
  final String citySort;
  final String cityName;
  final String areaSort;
  final String areaName;

  String get displayText => [
    regionName,
    cityName,
    areaName,
  ].where((item) => item.trim().isNotEmpty).join('-');
}
