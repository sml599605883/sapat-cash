import 'models/address_region_model.dart';

class AddressCache {
  const AddressCache._();

  static List<AddressRegionModel>? _regions;

  static List<AddressRegionModel>? get regions => _regions;

  static bool get hasRegions => _regions != null && _regions!.isNotEmpty;

  static bool get hasUsableRegions {
    final regions = _regions;
    if (regions == null || regions.isEmpty) {
      return false;
    }
    return regions.any((region) => region.cities.isNotEmpty);
  }

  static void save(List<AddressRegionModel> regions) {
    _regions = List<AddressRegionModel>.unmodifiable(regions);
  }

  static void clear() {
    _regions = null;
  }
}
