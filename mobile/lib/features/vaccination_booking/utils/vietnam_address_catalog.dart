import 'package:vietnam_provinces/vietnam_provinces.dart';

class VietnamAddressCatalog {
  VietnamAddressCatalog._();

  static const String provincePlaceholder = 'Chọn Tỉnh/Thành phố';
  static const String districtPlaceholder = 'Chọn Quận/Huyện';
  static const String wardPlaceholder = 'Chọn Phường/Xã';

  static bool _initialized = false;
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() {
    return _initFuture ??= VietnamProvinces.initialize().then((_) {
      _initialized = true;
    });
  }

  static List<dynamic> provinces() {
    if (!_initialized) return const [];
    return VietnamProvinces.getProvinces();
  }

  static dynamic provinceByName(String name) {
    if (!_initialized) return null;
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final province in provinces()) {
      final provinceName = _nameOf(province).toLowerCase();
      if (provinceName == normalized) return province;
    }
    final queried = VietnamProvinces.getProvinces(query: name.trim());
    if (queried.isNotEmpty) return queried.first;
    return null;
  }

  static List<dynamic> districtsByProvinceName(String provinceName) {
    if (!_initialized) return const [];
    final province = provinceByName(provinceName);
    final provinceCode = _codeOf(province);
    if (provinceCode == null) return const [];
    return VietnamProvinces.getDistricts(provinceCode: provinceCode);
  }

  static dynamic districtByName(String provinceName, String districtName) {
    if (!_initialized) return null;
    final normalized = districtName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final district in districtsByProvinceName(provinceName)) {
      final itemName = _nameOf(district).toLowerCase();
      if (itemName == normalized) return district;
    }
    final province = provinceByName(provinceName);
    final provinceCode = _codeOf(province);
    if (provinceCode != null) {
      final queried = VietnamProvinces.getDistricts(
        provinceCode: provinceCode,
        query: districtName.trim(),
      );
      if (queried.isNotEmpty) return queried.first;
    }
    return null;
  }

  static List<dynamic> wardsBySelection(String provinceName, String districtName) {
    if (!_initialized) return const [];
    final province = provinceByName(provinceName);
    final district = districtByName(provinceName, districtName);
    final provinceCode = _codeOf(province);
    final districtCode = _codeOf(district);
    if (provinceCode == null || districtCode == null) return const [];
    return VietnamProvinces.getWards(
      provinceCode: provinceCode,
      districtCode: districtCode,
    );
  }

  static String displayName(dynamic item) => _nameOf(item);

  static String _nameOf(dynamic item) {
    if (item == null) return '';
    final name = item.name;
    return name?.toString() ?? '';
  }

  static int? _codeOf(dynamic item) {
    if (item == null) return null;
    final code = item.code;
    return int.tryParse(code?.toString() ?? '');
  }
}
